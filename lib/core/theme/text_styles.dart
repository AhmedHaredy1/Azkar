import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Quran text style - Amiri font, 24sp
  /// Used for displaying Quranic verses
  static TextStyle get quranText => GoogleFonts.amiri(
        fontSize: 24,
        height: 2.0,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.normal,
      );

  /// Azkar text style - Amiri font, 22sp
  /// Used for displaying azkar and duas content
  static TextStyle get azkarText => GoogleFonts.amiri(
        fontSize: 22,
        height: 1.8,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.normal,
      );

  /// Body text style - Cairo font, 16sp
  /// Used for general body text and descriptions
  static TextStyle get bodyText => GoogleFonts.cairo(
        fontSize: 16,
        height: 1.5,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.normal,
      );

  /// Heading text style - Cairo font, 20sp bold
  /// Used for section titles and headings
  static TextStyle get headingText => GoogleFonts.cairo(
        fontSize: 20,
        height: 1.4,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      );

  /// Counter text style - Cairo font, 48sp bold
  /// Used for sebha counter display
  static TextStyle get counterText => GoogleFonts.cairo(
        fontSize: 48,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      );

  /// Small caption text - Cairo font, 12sp
  /// Used for metadata, source references
  static TextStyle get captionText => GoogleFonts.cairo(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.normal,
      );

  /// Category title - Cairo font, 18sp semi-bold
  /// Used for category list items
  static TextStyle get categoryTitle => GoogleFonts.cairo(
        fontSize: 18,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      );
}
