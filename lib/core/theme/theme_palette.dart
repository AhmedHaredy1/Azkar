import 'package:flutter/material.dart';

/// A palette of related colors that can be swapped at runtime.
///
/// Only the *accent* family (primary/secondary) varies between palettes.
/// Background, ink, hairline tones stay constant — they're set by
/// [AppColors] directly and shared across every palette so the warm
/// off-white aesthetic survives palette changes.
@immutable
class ThemePalette {
  final String id;
  final String nameAr;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primarySoft;
  final Color primaryInk;
  final Color secondary;
  final Color secondaryLight;
  final Color secondaryDark;
  final Color secondarySoft;

  const ThemePalette({
    required this.id,
    required this.nameAr,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primarySoft,
    required this.primaryInk,
    required this.secondary,
    required this.secondaryLight,
    required this.secondaryDark,
    required this.secondarySoft,
  });
}

/// Predefined palettes the user can pick from in Settings.
///
/// First entry is the default (Islamic green) — keeps the existing look
/// for users who never touch the picker.
class AppPalettes {
  AppPalettes._();

  /// Default — the app's signature deep Islamic green.
  /// (Original AppColors.primary / primaryLight / primaryDark.)
  static const ThemePalette green = ThemePalette(
    id: 'green',
    nameAr: 'أخضر إسلامي',
    primary: Color(0xFF1B5E20),
    primaryLight: Color(0xFF2E7D32),
    primaryDark: Color(0xFF0F3A13),
    primarySoft: Color(0xFFEEF3EE),
    primaryInk: Color(0xFF0F3A13),
    secondary: Color(0xFFB8892A),
    secondaryLight: Color(0xFFD5B76A),
    secondaryDark: Color(0xFF8A6420),
    secondarySoft: Color(0xFFF5ECD9),
  );

  /// The dark teal already used by Ramadan hero gradients
  /// (#1B3A3F → #0F2326). Promoted to a full palette.
  static const ThemePalette teal = ThemePalette(
    id: 'teal',
    nameAr: 'فيروزي',
    primary: Color(0xFF1B3A3F),
    primaryLight: Color(0xFF2A565C),
    primaryDark: Color(0xFF0F2326),
    primarySoft: Color(0xFFE8EEEF),
    primaryInk: Color(0xFF0F2326),
    secondary: Color(0xFFB8892A),
    secondaryLight: Color(0xFFD5B76A),
    secondaryDark: Color(0xFF8A6420),
    secondarySoft: Color(0xFFF5ECD9),
  );

  /// Built from the existing gold accent (AppColors.secondary family).
  /// Primary becomes gold; the green family moves to "secondary" so
  /// both warm tones still appear together.
  static const ThemePalette gold = ThemePalette(
    id: 'gold',
    nameAr: 'ذهبي',
    primary: Color(0xFF8A6420),
    primaryLight: Color(0xFFB8892A),
    primaryDark: Color(0xFF8A6420),
    primarySoft: Color(0xFFF5ECD9),
    primaryInk: Color(0xFF8A6420),
    secondary: Color(0xFF1B5E20),
    secondaryLight: Color(0xFF2E7D32),
    secondaryDark: Color(0xFF0F3A13),
    secondarySoft: Color(0xFFEEF3EE),
  );

  /// The near-black ink already used as the Streaks hero background
  /// (AppColors.ink / textPrimary). Promoted to a palette so the
  /// monochrome look can apply app-wide.
  static const ThemePalette charcoal = ThemePalette(
    id: 'charcoal',
    nameAr: 'فحمي',
    primary: Color(0xFF141814),
    primaryLight: Color(0xFF4A524B),
    primaryDark: Color(0xFF000000),
    primarySoft: Color(0xFFF2EFE8),
    primaryInk: Color(0xFF141814),
    secondary: Color(0xFFB8892A),
    secondaryLight: Color(0xFFD5B76A),
    secondaryDark: Color(0xFF8A6420),
    secondarySoft: Color(0xFFF5ECD9),
  );

  /// Lookup order — also the order shown in the picker.
  static const List<ThemePalette> all = [
    green,
    teal,
    gold,
    charcoal,
  ];

  static ThemePalette byId(String? id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return green;
  }
}

/// Mutable global pointing at the currently active palette.
/// Read by [AppColors] getters so every existing call site picks
/// up the user's choice without each screen having to listen.
class ActivePalette {
  ActivePalette._();
  static ThemePalette _current = AppPalettes.green;
  static ThemePalette get current => _current;
  static void set(ThemePalette palette) {
    _current = palette;
  }
}
