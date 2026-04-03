import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/quran_page.dart';

class MushafPageWidget extends StatelessWidget {
  final QuranPage page;
  final double fontSize;

  const MushafPageWidget({
    super.key,
    required this.page,
    this.fontSize = 21,
  });

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF6EF),
      child: Column(
        children: [
          // Top bar: juz + page info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBE0),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الجزء ${_toArabicNumber(page.juz)}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (page.sections.isNotEmpty)
                  Text(
                    page.sections.first.surahNameAr,
                    style: GoogleFonts.amiri(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  _toArabicNumber(page.pageNumber),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Page content
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    for (final section in page.sections) ...[
                      if (section.showSurahHeader) _buildSurahHeader(section),
                      if (section.showBismillah) _buildBismillah(),
                      _buildAyahText(section),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Bottom page number
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBE0),
              border: Border(
                top: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Center(
              child: Text(
                '- ${_toArabicNumber(page.pageNumber)} -',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahHeader(PageSurahSection section) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Decorative top
          Text(
            '﴾ سُورَةُ ${section.surahNameAr} ﴿',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillah() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: fontSize + 1,
          color: AppColors.textPrimary,
          height: 1.8,
        ),
      ),
    );
  }

  Widget _buildAyahText(PageSurahSection section) {
    // Build continuous flowing text with ayah markers
    final List<InlineSpan> spans = [];

    for (final ayah in section.ayahs) {
      // Ayah text
      spans.add(TextSpan(
        text: ayah.text,
        style: GoogleFonts.amiri(
          fontSize: fontSize,
          height: 2.0,
          color: const Color(0xFF1A1A1A),
          letterSpacing: 0,
        ),
      ));
      // Ayah number marker
      spans.add(TextSpan(
        text: ' \uFD3F${_toArabicNumber(ayah.ayahNumber)}\uFD3E ',
        style: GoogleFonts.amiri(
          fontSize: fontSize - 3,
          color: AppColors.secondary,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        text: TextSpan(children: spans),
      ),
    );
  }
}
