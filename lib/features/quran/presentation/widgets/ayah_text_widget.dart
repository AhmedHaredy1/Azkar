import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/ayah.dart';

class AyahTextWidget extends StatelessWidget {
  final Ayah ayah;
  final double fontSize;

  const AyahTextWidget({
    super.key,
    required this.ayah,
    this.fontSize = 24,
  });

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: [
            TextSpan(
              text: '${ayah.textAr} ',
              style: GoogleFonts.amiri(
                fontSize: fontSize,
                height: 2.0,
                color: AppColors.textPrimary,
              ),
            ),
            // Ayah number in circle-style
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _toArabicNumber(ayah.number),
                  style: GoogleFonts.cairo(
                    fontSize: fontSize * 0.45,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
