import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../domain/models/quran_page.dart';
import '../domain/models/surah.dart';

class QuranLocalSource {
  List<Surah>? _cachedSurahs;
  Map<int, QuranPage>? _cachedPages;

  Future<List<Surah>> loadSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;

    final jsonString = await rootBundle.loadString(AppAssets.quranData);
    final decoded = json.decode(jsonString);

    List<dynamic> jsonList;
    if (decoded is Map<String, dynamic> && decoded.containsKey('surahs')) {
      jsonList = decoded['surahs'] as List<dynamic>;
    } else if (decoded is List<dynamic>) {
      jsonList = decoded;
    } else {
      jsonList = [];
    }

    _cachedSurahs = jsonList
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cachedSurahs!;
  }

  Future<Surah?> getSurahByNumber(int number) async {
    final surahs = await loadSurahs();
    try {
      return surahs.firstWhere((s) => s.number == number);
    } catch (_) {
      return null;
    }
  }

  /// Strip the Bismillah prefix from ayah text if present.
  /// Matches بسم + الله + الرحمن + الرحيم with any diacritics between letters.
  static final _bismillahPattern = RegExp(
    r'^\s*\uFEFF?\s*'           // optional BOM + whitespace
    r'ب[\u0610-\u065F\u0670]*'  // ب
    r'س[\u0610-\u065F\u0670]*'  // س
    r'م[\u0610-\u065F\u0670]*'  // م
    r'\s+'
    r'[ٱا][\u0610-\u065F\u0670]*' // ا or ٱ
    r'ل[\u0610-\u065F\u0670]*'
    r'ل[\u0610-\u065F\u0670]*'
    r'ه[\u0610-\u065F\u0670]*'
    r'\s+'
    r'[ٱا][\u0610-\u065F\u0670]*'
    r'ل[\u0610-\u065F\u0670]*'
    r'ر[\u0610-\u065F\u0670]*'
    r'ح[\u0610-\u065F\u0670]*'
    r'م[\u0610-\u065F\u0670\u0670]*' // مَٰ
    r'ن[\u0610-\u065F\u0670]*'
    r'\s+'
    r'[ٱا][\u0610-\u065F\u0670]*'
    r'ل[\u0610-\u065F\u0670]*'
    r'ر[\u0610-\u065F\u0670]*'
    r'ح[\u0610-\u065F\u0670]*'
    r'ي[\u0610-\u065F\u0670]*'
    r'م[\u0610-\u065F\u0670]*'
    r'\s*',
  );

  static String _stripBismillah(String text) {
    final match = _bismillahPattern.firstMatch(text);
    if (match != null) {
      final after = text.substring(match.end).trimLeft();
      if (after.isNotEmpty) return after;
    }
    return text;
  }

  Future<Map<int, QuranPage>> buildPageIndex() async {
    if (_cachedPages != null) return _cachedPages!;

    final surahs = await loadSurahs();

    // Collect all ayahs with surah info, grouped by page
    final Map<int, List<_AyahEntry>> pageAyahs = {};

    for (final surah in surahs) {
      for (int i = 0; i < surah.ayahs.length; i++) {
        final ayah = surah.ayahs[i];
        // Strip Bismillah from first ayah text (except surah 1 & 9)
        // Surah 1: Bismillah IS the ayah itself
        // Surah 9: No Bismillah
        String ayahText = ayah.textAr;
        if (ayah.number == 1 && surah.number != 1 && surah.number != 9) {
          ayahText = _stripBismillah(ayahText);
        }

        final entry = _AyahEntry(
          surahNumber: surah.number,
          surahNameAr: surah.nameAr,
          ayahNumber: ayah.number,
          text: ayahText,
          page: ayah.page,
          juz: ayah.juz,
          isFirstAyah: ayah.number == 1,
        );
        pageAyahs.putIfAbsent(ayah.page, () => []).add(entry);
      }
    }

    // Build QuranPage for each page
    final Map<int, QuranPage> pages = {};

    for (final pageNum in pageAyahs.keys) {
      final entries = pageAyahs[pageNum]!;
      final juz = entries.first.juz;

      // Group entries by surah (preserve order)
      final List<PageSurahSection> sections = [];
      int? currentSurah;
      List<PageAyah> currentAyahs = [];
      String currentSurahName = '';
      bool currentShowHeader = false;

      for (final entry in entries) {
        if (entry.surahNumber != currentSurah) {
          // Save previous section
          if (currentAyahs.isNotEmpty) {
            sections.add(PageSurahSection(
              surahNumber: currentSurah!,
              surahNameAr: currentSurahName,
              showSurahHeader: currentShowHeader,
              showBismillah: currentShowHeader && currentSurah != 9 && currentSurah != 1,
              ayahs: List.from(currentAyahs),
            ));
          }
          // Start new section
          currentSurah = entry.surahNumber;
          currentSurahName = entry.surahNameAr;
          currentShowHeader = entry.isFirstAyah;
          currentAyahs = [];
        }
        currentAyahs.add(PageAyah(
          surahNumber: entry.surahNumber,
          ayahNumber: entry.ayahNumber,
          text: entry.text,
        ));
      }
      // Save last section
      if (currentAyahs.isNotEmpty && currentSurah != null) {
        sections.add(PageSurahSection(
          surahNumber: currentSurah,
          surahNameAr: currentSurahName,
          showSurahHeader: currentShowHeader,
          showBismillah: currentShowHeader && currentSurah != 9 && currentSurah != 1,
          ayahs: List.from(currentAyahs),
        ));
      }

      pages[pageNum] = QuranPage(
        pageNumber: pageNum,
        juz: juz,
        sections: sections,
      );
    }

    _cachedPages = pages;
    return pages;
  }

  Future<int> getPageForSurah(int surahNumber) async {
    final surahs = await loadSurahs();
    try {
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      if (surah.ayahs.isNotEmpty) {
        return surah.ayahs.first.page;
      }
    } catch (_) {}
    return 1;
  }

  Future<List<SearchResult>> searchAyahs(String query) async {
    if (query.trim().isEmpty) return [];
    final surahs = await loadSurahs();
    final results = <SearchResult>[];

    for (final surah in surahs) {
      for (final ayah in surah.ayahs) {
        if (ayah.textAr.contains(query)) {
          results.add(SearchResult(
            surahNumber: surah.number,
            surahNameAr: surah.nameAr,
            ayahNumber: ayah.number,
            text: ayah.textAr,
            page: ayah.page,
          ));
        }
        if (results.length >= 50) break;
      }
      if (results.length >= 50) break;
    }
    return results;
  }
}

class _AyahEntry {
  final int surahNumber;
  final String surahNameAr;
  final int ayahNumber;
  final String text;
  final int page;
  final int juz;
  final bool isFirstAyah;

  const _AyahEntry({
    required this.surahNumber,
    required this.surahNameAr,
    required this.ayahNumber,
    required this.text,
    required this.page,
    required this.juz,
    required this.isFirstAyah,
  });
}
