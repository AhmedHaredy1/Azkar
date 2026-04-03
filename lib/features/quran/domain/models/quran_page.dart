class PageAyah {
  final int surahNumber;
  final int ayahNumber;
  final String text;

  const PageAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
  });
}

class PageSurahSection {
  final int surahNumber;
  final String surahNameAr;
  final bool showSurahHeader;
  final bool showBismillah;
  final List<PageAyah> ayahs;

  const PageSurahSection({
    required this.surahNumber,
    required this.surahNameAr,
    required this.showSurahHeader,
    required this.showBismillah,
    required this.ayahs,
  });
}

class QuranPage {
  final int pageNumber;
  final int juz;
  final List<PageSurahSection> sections;

  const QuranPage({
    required this.pageNumber,
    required this.juz,
    required this.sections,
  });
}

class SearchResult {
  final int surahNumber;
  final String surahNameAr;
  final int ayahNumber;
  final String text;
  final int page;

  const SearchResult({
    required this.surahNumber,
    required this.surahNameAr,
    required this.ayahNumber,
    required this.text,
    required this.page,
  });
}
