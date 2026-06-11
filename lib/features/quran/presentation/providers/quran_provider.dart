import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/storage_service.dart';
import '../../../mushaf/domain/models/mushaf_type.dart';
import '../../data/quran_local_source.dart';
import '../../data/quran_repository_impl.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/quran_page.dart';
import '../../domain/models/surah.dart';
import '../../domain/repositories/quran_repository.dart';

export '../../data/quran_local_source.dart' show JuzInfo;

final quranLocalSourceProvider = Provider<QuranLocalSource>((ref) {
  return QuranLocalSource();
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepositoryImpl(ref.read(quranLocalSourceProvider));
});

final surahListProvider = FutureProvider<List<Surah>>((ref) {
  return ref.read(quranRepositoryProvider).getSurahs();
});

// Juz list provider
final juzListProvider = FutureProvider<List<JuzInfo>>((ref) {
  return ref.read(quranLocalSourceProvider).getJuzList();
});

final surahProvider = FutureProvider.family<Surah?, int>((ref, number) {
  return ref.read(quranRepositoryProvider).getSurahByNumber(number);
});

// Page index for Mushaf view
final pageIndexProvider = FutureProvider<Map<int, QuranPage>>((ref) {
  return ref.read(quranLocalSourceProvider).buildPageIndex();
});

// Current page being viewed
final currentPageProvider = StateProvider<int>((ref) => 1);

// Last read page (persisted)
class LastReadPageNotifier extends StateNotifier<int> {
  final StorageService _storage;

  LastReadPageNotifier(this._storage)
      : super(_storage.getSetting<int>(StorageKeys.lastReadPage) ?? 1);

  void setPage(int page) {
    state = page;
    _storage.putSetting(StorageKeys.lastReadPage, page);
  }
}

final lastReadPageProvider =
    StateNotifierProvider<LastReadPageNotifier, int>((ref) {
  return LastReadPageNotifier(ref.watch(storageServiceProvider));
});

// Get page number for a surah
final surahPageProvider = FutureProvider.family<int, int>((ref, surahNumber) {
  return ref.read(quranLocalSourceProvider).getPageForSurah(surahNumber);
});

// ── Text layout ↔ PDF mushaf page mapping ──
// The text reader uses the standard 604-page layout. Madinah-layout PDFs
// match it page-for-page; other layouts are mapped proportionally within
// the surah's span (exact at surah starts).

/// The surah's text-layout page span (start, end inclusive).
Future<(int, int)> _textSpanForSurah(Ref ref, int surah) async {
  final src = ref.read(quranLocalSourceProvider);
  final start = await src.getPageForSurah(surah);
  var end = 604;
  if (surah < 114) {
    end = await src.getPageForSurah(surah + 1) - 1;
    if (end < start) end = start;
  }
  return (start, end);
}

/// PDF page of a mushaf for a standard text-layout page.
final textToPdfPageProvider =
    FutureProvider.family<int, ({String mushafId, int textPage})>(
        (ref, arg) async {
  final mushaf = getMushafById(arg.mushafId);
  if (mushaf == null) return arg.textPage;
  if (mushaf.isMadinahLayout) {
    return mushaf.pdfPageFromMushaf(arg.textPage);
  }
  final pageIndex = await ref.watch(pageIndexProvider.future);
  final surah =
      pageIndex[arg.textPage]?.sections.firstOrNull?.surahNumber ?? 1;
  final (textStart, textEnd) = await _textSpanForSurah(ref, surah);
  final pdfStart = mushaf.getSurahStartPage(surah);
  final pdfEnd = mushaf.getSurahEndPage(surah);
  final span = textEnd - textStart;
  final frac =
      span <= 0 ? 0.0 : ((arg.textPage - textStart) / span).clamp(0.0, 1.0);
  return (pdfStart + frac * (pdfEnd - pdfStart))
      .round()
      .clamp(1, mushaf.totalPdfPages);
});

/// Standard text-layout page shown on a mushaf's PDF page.
final pdfToTextPageProvider =
    FutureProvider.family<int, ({String mushafId, int pdfPage})>(
        (ref, arg) async {
  final mushaf = getMushafById(arg.mushafId);
  if (mushaf == null) return arg.pdfPage.clamp(1, 604);
  if (mushaf.isMadinahLayout) {
    return mushaf.mushafPageFromPdf(arg.pdfPage).clamp(1, 604);
  }
  final surah = mushaf.getSurahForPage(arg.pdfPage) ?? 1;
  final (textStart, textEnd) = await _textSpanForSurah(ref, surah);
  final pdfStart = mushaf.getSurahStartPage(surah);
  final pdfEnd = mushaf.getSurahEndPage(surah);
  final span = pdfEnd - pdfStart;
  final frac =
      span <= 0 ? 0.0 : ((arg.pdfPage - pdfStart) / span).clamp(0.0, 1.0);
  return (textStart + frac * (textEnd - textStart)).round().clamp(1, 604);
});

// Search
final quranSearchProvider =
    FutureProvider.family<List<SearchResult>, String>((ref, query) {
  return ref.read(quranLocalSourceProvider).searchAyahs(query);
});

// Highlighted ayah (reading position marker)
class HighlightedAyah {
  final int surahNumber;
  final int ayahNumber;
  final int page;

  const HighlightedAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
  });

  String get key => '${surahNumber}_$ayahNumber';
}

class HighlightedAyahNotifier extends StateNotifier<HighlightedAyah?> {
  final StorageService _storage;

  HighlightedAyahNotifier(this._storage) : super(null) {
    _load();
  }

  void _load() {
    final surah = _storage.getSetting<int>(StorageKeys.highlightSurah);
    final ayah = _storage.getSetting<int>(StorageKeys.highlightAyah);
    final page = _storage.getSetting<int>(StorageKeys.highlightPage);
    if (surah != null && ayah != null && page != null) {
      state = HighlightedAyah(
        surahNumber: surah,
        ayahNumber: ayah,
        page: page,
      );
    }
  }

  void setHighlight(int surahNumber, int ayahNumber, int page) {
    state = HighlightedAyah(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      page: page,
    );
    _storage.putSetting(StorageKeys.highlightSurah, surahNumber);
    _storage.putSetting(StorageKeys.highlightAyah, ayahNumber);
    _storage.putSetting(StorageKeys.highlightPage, page);
  }

  void clearHighlight() {
    state = null;
    _storage.deleteSetting(StorageKeys.highlightSurah);
    _storage.deleteSetting(StorageKeys.highlightAyah);
    _storage.deleteSetting(StorageKeys.highlightPage);
  }
}

final highlightedAyahProvider =
    StateNotifierProvider<HighlightedAyahNotifier, HighlightedAyah?>((ref) {
  return HighlightedAyahNotifier(ref.watch(storageServiceProvider));
});

// Bookmarks
class BookmarkNotifier extends StateNotifier<List<Bookmark>> {
  final StorageService _storage;

  BookmarkNotifier(this._storage) : super([]) {
    _loadBookmarks();
  }

  void _loadBookmarks() {
    final raw = _storage.getBookmarks();
    final bookmarks = <Bookmark>[];
    for (final item in raw) {
      if (item is String) {
        try {
          final map = json.decode(item) as Map<String, dynamic>;
          bookmarks.add(Bookmark.fromJson(map));
        } catch (_) {}
      } else if (item is Map) {
        bookmarks.add(Bookmark.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    state = bookmarks;
  }

  Future<void> toggleBookmark(int surahNumber, int ayahNumber) async {
    final key = '${surahNumber}_$ayahNumber';
    if (_storage.isBookmarked(key)) {
      await _storage.removeBookmark(key);
    } else {
      final bookmark = Bookmark(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        createdAt: DateTime.now(),
      );
      await _storage.addBookmark(key, json.encode(bookmark.toJson()));
    }
    _loadBookmarks();
  }

  bool isBookmarked(int surahNumber, int ayahNumber) {
    final key = '${surahNumber}_$ayahNumber';
    return _storage.isBookmarked(key);
  }
}

final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, List<Bookmark>>((ref) {
  return BookmarkNotifier(ref.watch(storageServiceProvider));
});
