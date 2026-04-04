import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/quran_page.dart';

class MushafPageWidget extends StatelessWidget {
  final QuranPage page;
  final double fontSize;

  const MushafPageWidget({
    super.key,
    required this.page,
    this.fontSize = 22,
  });

  static const _mushafBg = Color(0xFFFFF8EC);
  static const _frameColor = Color(0xFFB8860B);
  static const _headerBg = Color(0xFFF5E6C8);
  static const _textColor = Color(0xFF1C1C1C);
  static const _ayahMarkerColor = Color(0xFF8B6914);

  String _toArabicNumber(int number) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _mushafBg,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _mushafBg,
                border: Border.all(color: _frameColor.withValues(alpha: 0.6), width: 2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                children: [
                  // Inner frame with double border effect
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _frameColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Top header: Juz + Surah name + Page
                          _buildTopHeader(),
                          // Decorative line
                          _buildDecorativeLine(),
                          // Main Quran text area
                          Expanded(
                            child: _buildTextArea(),
                          ),
                          // Bottom decorative line
                          _buildDecorativeLine(),
                          // Bottom: page number
                          _buildBottomBar(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    String surahName = '';
    if (page.sections.isNotEmpty) {
      surahName = page.sections.last.surahNameAr;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: _headerBg.withValues(alpha: 0.5),
      child: Row(
        children: [
          // Juz
          Text(
            'الجزء ${_toArabicNumber(page.juz)}',
            style: GoogleFonts.amiri(
              fontSize: 11,
              color: _frameColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Surah name
          Text(
            'سُورَةُ $surahName',
            style: GoogleFonts.amiri(
              fontSize: 13,
              color: _frameColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Page number
          Text(
            _toArabicNumber(page.pageNumber),
            style: GoogleFonts.amiri(
              fontSize: 11,
              color: _frameColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeLine() {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _frameColor.withValues(alpha: 0.0),
            _frameColor.withValues(alpha: 0.6),
            _frameColor,
            _frameColor.withValues(alpha: 0.6),
            _frameColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildTextArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          for (int i = 0; i < page.sections.length; i++) ...[
            if (page.sections[i].showSurahHeader)
              _buildSurahTitle(page.sections[i]),
            if (page.sections[i].showBismillah) _buildBismillah(),
            _buildSectionText(page.sections[i]),
            if (i < page.sections.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildSurahTitle(PageSurahSection section) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _frameColor.withValues(alpha: 0.08),
            _frameColor.withValues(alpha: 0.2),
            _frameColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _frameColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left & Right ornaments
          Positioned(
            left: 12,
            child: Text(
              '❁',
              style: TextStyle(
                fontSize: 14,
                color: _frameColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            right: 12,
            child: Text(
              '❁',
              style: TextStyle(
                fontSize: 14,
                color: _frameColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Surah name
          Text(
            'سُورَةُ ${section.surahNameAr}',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3E2723),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillah() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: fontSize - 1,
          color: _textColor,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSectionText(PageSurahSection section) {
    final spans = <InlineSpan>[];

    for (final ayah in section.ayahs) {
      // Ayah text
      spans.add(TextSpan(
        text: ayah.text,
        style: GoogleFonts.amiri(
          fontSize: fontSize,
          height: 1.95,
          color: _textColor,
          wordSpacing: 2,
        ),
      ));
      // Ayah end marker: ﴿١﴾
      spans.add(TextSpan(
        text: ' \u06DD${_toArabicNumber(ayah.ayahNumber)} ',
        style: GoogleFonts.amiri(
          fontSize: fontSize - 2,
          color: _ayahMarkerColor,
          height: 1.95,
        ),
      ));
    }

    return RichText(
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      softWrap: true,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: _headerBg.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _frameColor.withValues(alpha: 0.3)),
              bottom: BorderSide(color: _frameColor.withValues(alpha: 0.3)),
            ),
          ),
          child: Text(
            _toArabicNumber(page.pageNumber),
            style: GoogleFonts.amiri(
              fontSize: 13,
              color: _frameColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
