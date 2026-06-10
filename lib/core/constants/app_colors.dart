import 'package:flutter/material.dart';

import '../theme/theme_palette.dart';

/// Design system — minimal, modern, spiritual.
/// Restrained accent on warm off-white. Gold reserved for highlight
/// moments (Quran hero, streaks). Single ornament: 8-point star.
///
/// Palette-dependent fields (primary*, secondary*, navBarSelected) are
/// non-const getters that read from [ActivePalette]. Layout-neutral
/// fields (background, ink, hairline, etc.) stay `static const` because
/// they don't change between palettes.
class AppColors {
  AppColors._();

  // ── Palette-dependent (runtime-swappable) ──
  static Color get primary => ActivePalette.current.primary;
  static Color get primaryLight => ActivePalette.current.primaryLight;
  static Color get primaryDark => ActivePalette.current.primaryDark;
  static Color get primarySoft => ActivePalette.current.primarySoft;
  static Color get primaryInk => ActivePalette.current.primaryInk;
  static Color get secondary => ActivePalette.current.secondary;
  static Color get secondaryLight => ActivePalette.current.secondaryLight;
  static Color get secondaryDark => ActivePalette.current.secondaryDark;
  static Color get secondarySoft => ActivePalette.current.secondarySoft;

  // Background & Surface (constant across palettes)
  static const Color background = Color(0xFFFAF8F3); // warm off-white page bg
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSunk = Color(0xFFF2EFE8); // quiet sunken surfaces
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0x141B2F1F); // hairline

  // Text / ink scale
  static const Color textPrimary = Color(0xFF141814);
  static const Color textSecondary = Color(0xFF4A524B);
  static const Color textTertiary = Color(0xFF8A8F88);
  static const Color textPlaceholder = Color(0xFFB8BAB4);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF141814);

  /// Aliases matching the design tokens file (T.ink, T.ink2, T.ink3, T.ink4).
  static const Color ink = textPrimary;
  static const Color ink2 = textSecondary;
  static const Color ink3 = textTertiary;
  static const Color ink4 = textPlaceholder;

  // Hairlines — subtle borders used on cards + dividers.
  static const Color hairline = Color(0x141B2F1F); // rgba(27,47,31,0.08)
  static const Color hairlineStrong = Color(0x241B2F1F); // rgba(27,47,31,0.14)

  // Utility
  static const Color divider = hairline;
  static const Color error = Color(0xFFB42318);
  static const Color success = Color(0xFF1B5E20);
  static const Color shimmer = Color(0xFFE8E4DB);

  // Bottom Navigation (Light) — selected color tracks the palette.
  static const Color navBarBackground = Color(0xFFFFFFFF);
  static Color get navBarSelected => ActivePalette.current.primary;
  static const Color navBarUnselected = Color(0xFF8A8F88);

  // ── Dark mode aliases (kept for backward-compat with files that still
  // reference them; dark mode itself has been removed — all map to light
  // tones). New code should use the light constants directly.
  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkCard = card;
  static const Color darkCardBorder = cardBorder;
  static const Color darkTextPrimary = textPrimary;
  static const Color darkTextSecondary = textSecondary;
  static const Color darkDivider = divider;
  static const Color darkShimmer = shimmer;
  static const Color darkNavBarBackground = navBarBackground;
  static const Color darkNavBarUnselected = navBarUnselected;
}
