import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/quran_page.dart';
import '../providers/quran_audio_provider.dart';
import '../providers/quran_provider.dart';

class MushafPageWidget extends ConsumerWidget {
  final QuranPage page;
  final VoidCallback? onToggleControls;

  const MushafPageWidget({
    super.key,
    required this.page,
    this.onToggleControls,
  });

  static const _mushafBg = Color(0xFFFFF8EC);
  static const _frameColor = Color(0xFFB8860B);
  static const _headerBg = Color(0xFFF5E6C8);
  static const _textColor = Color(0xFF1C1C1C);
  static const _ayahMarkerColor = Color(0xFF8B6914);
  static const _highlightColor = Color(0xFF90CAF9);

  String _toArabicNumber(int number) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlighted = ref.watch(highlightedAyahProvider);

    return GestureDetector(
      onTap: onToggleControls,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: _mushafBg,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _mushafBg,
              border: Border.all(
                color: _frameColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _frameColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  _buildTopHeader(),
                  Container(
                    height: 1,
                    color: _frameColor.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: _buildTextArea(ref, highlighted),
                  ),
                  Container(
                    height: 1,
                    color: _frameColor.withValues(alpha: 0.4),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final surahName =
        page.sections.isNotEmpty ? page.sections.last.surahNameAr : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      color: _headerBg.withValues(alpha: 0.4),
      child: Row(
        children: [
          Text(
            'الجزء ${_toArabicNumber(page.juz)}',
            style: GoogleFonts.amiri(fontSize: 10, color: _frameColor),
          ),
          const Spacer(),
          Text(
            'سورة $surahName',
            style: GoogleFonts.amiri(
              fontSize: 12,
              color: _frameColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            _toArabicNumber(page.pageNumber),
            style: GoogleFonts.amiri(fontSize: 10, color: _frameColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea(WidgetRef ref, HighlightedAyah? highlighted) {
    final totalTextLength = page.sections.fold<int>(
      0,
      (s, sec) => s + sec.ayahs.fold<int>(0, (a, ay) => a + ay.text.length),
    );

    // Adaptive font size — slightly larger overall for readability while
    // keeping the same ayah-per-page layout.
    double fontSize;
    if (totalTextLength > 1200) {
      fontSize = 21;
    } else if (totalTextLength > 800) {
      fontSize = 23;
    } else if (totalTextLength > 400) {
      fontSize = 25;
    } else {
      fontSize = 27;
    }

    final sectionWidgets = <Widget>[];

    for (final section in page.sections) {
      if (section.showSurahHeader) {
        sectionWidgets.add(_buildSurahHeader(section));
      }
      if (section.showBismillah) {
        sectionWidgets.add(_buildBismillah(fontSize));
      }

      // Build one continuous RichText for all ayahs in this section
      // This gives proper flowing justified Arabic text
      final spans = <InlineSpan>[];

      for (final ayah in section.ayahs) {
        final isHighlighted = highlighted != null &&
            highlighted.surahNumber == section.surahNumber &&
            highlighted.ayahNumber == ayah.ayahNumber;

        // Ayah text span
        spans.add(TextSpan(
          text: ayah.text,
          style: GoogleFonts.amiri(
            fontSize: fontSize,
            height: 1.9,
            color: _textColor,
            backgroundColor: isHighlighted
                ? _highlightColor.withValues(alpha: 0.4)
                : null,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // Highlight the ayah
              ref.read(highlightedAyahProvider.notifier).setHighlight(
                    section.surahNumber,
                    ayah.ayahNumber,
                    page.pageNumber,
                  );
              // If audio is playing, seek to this ayah
              final audio = ref.read(quranAudioProvider);
              if (audio.isPlaying || audio.currentSurah != null) {
                ref.read(quranAudioProvider.notifier).playFromAyah(
                      section.surahNumber,
                      ayah.ayahNumber,
                    );
              }
            },
        ));

        // Ayah number marker
        spans.add(TextSpan(
          text: ' \u06DD${_toArabicNumber(ayah.ayahNumber)} ',
          style: GoogleFonts.amiri(
            fontSize: fontSize - 3,
            color: _ayahMarkerColor,
            height: 1.9,
            backgroundColor: isHighlighted
                ? _highlightColor.withValues(alpha: 0.4)
                : null,
          ),
        ));
      }

      sectionWidgets.add(
        SizedBox(
          width: double.infinity,
          child: RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(children: spans),
          ),
        ),
      );
    }

    // Center the ayah content vertically so short pages (e.g. short surahs)
    // don't leave a large empty block at the bottom. The ayah distribution
    // per page is unchanged — this only rebalances whitespace visually.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: sectionWidgets,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurahHeader(PageSurahSection section) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _frameColor.withValues(alpha: 0.05),
            _frameColor.withValues(alpha: 0.15),
            _frameColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _frameColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'سُورَةُ ${section.surahNameAr}',
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3E2723),
          ),
        ),
      ),
    );
  }

  Widget _buildBismillah(double fontSize) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: fontSize - 2,
          color: _textColor,
          height: 1.8,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      color: _headerBg.withValues(alpha: 0.4),
      child: Center(
        child: Text(
          _toArabicNumber(page.pageNumber),
          style: GoogleFonts.amiri(fontSize: 11, color: _frameColor),
        ),
      ),
    );
  }
}
