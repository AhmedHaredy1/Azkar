import 'package:flutter/material.dart';

/// Spacing scale on a 4pt grid. Prefer these over literal numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets screen =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets card = EdgeInsets.all(lg);
}

/// Corner radius scale. Cards default to [lg]; hero surfaces to [xl].
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(xl));
  static const BorderRadius bottomSheet =
      BorderRadius.vertical(top: Radius.circular(xxl));
}

/// Standard elevations. Relies on M3 surface tint rather than heavy shadows.
class AppElevation {
  AppElevation._();

  static const double none = 0;
  static const double sm = 1;
  static const double md = 2;
  static const double lg = 6;
}
