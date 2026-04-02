import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';
import '../../data/quran_local_source.dart';
import '../../data/quran_repository_impl.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/surah.dart';
import '../../domain/repositories/quran_repository.dart';

final quranLocalSourceProvider = Provider<QuranLocalSource>((ref) {
  return QuranLocalSource();
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepositoryImpl(ref.read(quranLocalSourceProvider));
});

final surahListProvider = FutureProvider<List<Surah>>((ref) {
  return ref.read(quranRepositoryProvider).getSurahs();
});

final surahProvider = FutureProvider.family<Surah?, int>((ref, number) {
  return ref.read(quranRepositoryProvider).getSurahByNumber(number);
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
        } catch (_) {
          // skip invalid
        }
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
  return BookmarkNotifier(StorageService.instance);
});
