import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Text widget optimized for Arabic content.
/// Defaults to Amiri font, right-aligned, with Arabic locale.
class ArabicText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;

  const ArabicText(
    this.text, {
    super.key,
    this.fontSize = 20.0,
    this.fontWeight = FontWeight.normal,
    this.color = AppColors.textPrimary,
    this.textAlign = TextAlign.right,
    this.maxLines,
    this.overflow,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: overflow,
      locale: const Locale('ar'),
      style: GoogleFonts.amiri(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.8,
      ),
    );
  }
}
