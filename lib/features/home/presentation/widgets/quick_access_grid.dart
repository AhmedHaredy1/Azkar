import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';

class _QuickAccessItem {
  final String label;
  final IconData icon;
  final String route;

  const _QuickAccessItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// الأقسام grid — sits on the deep-green home zone. Cream tiles with
/// gold-soft borders and dark-green icons. Layout follows the mockup:
///
///   [3-up] المصحف ، الأذكار ، الأدعية
///   [3-up] المساجد ، القبلة ، المسبحة
///   [2-up wide] البث المباشر ، استمع للقرآن
///   [3-up] أسماء الله ، حديث اليوم ، رمضان
///
/// Remaining feature tiles continue below in 3-up rows so every section
/// stays reachable without removing anything from the home.
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  // Top-priority tiles — order matches the mockup exactly.
  static const _row1 = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'المصحف',
      icon: Icons.menu_book_rounded,
      route: '/quran',
    ),
    _QuickAccessItem(
      label: 'الأذكار',
      icon: Icons.auto_stories_rounded,
      route: '/azkar',
    ),
    _QuickAccessItem(
      label: 'الأدعية',
      icon: Icons.volunteer_activism_rounded,
      route: '/duas',
    ),
  ];

  static const _row2 = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'المساجد',
      icon: Icons.mosque_rounded,
      route: '/nearby-mosques',
    ),
    _QuickAccessItem(
      label: 'القبلة',
      icon: Icons.explore_rounded,
      route: '/qibla',
    ),
    _QuickAccessItem(
      label: 'المسبحة',
      icon: Icons.radio_button_checked_rounded,
      route: '/sebha',
    ),
  ];

  static const _wideRow = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'البث المباشر',
      icon: Icons.radio_rounded,
      route: '/live-radio',
    ),
    _QuickAccessItem(
      label: 'استمع للقرآن',
      icon: Icons.headphones_rounded,
      route: '/quran-listen',
    ),
  ];

  static const _row4 = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'أسماء الله',
      icon: Icons.star_outline_rounded,
      route: '/asma-allah',
    ),
    _QuickAccessItem(
      label: 'حديث اليوم',
      icon: Icons.format_quote_rounded,
      route: '/hadith-of-day',
    ),
    _QuickAccessItem(
      label: 'رمضان',
      icon: Icons.brightness_3_rounded,
      route: '/ramadan',
    ),
  ];

  // Remaining tiles — kept so every feature stays reachable from home.
  static const _rest = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'مواقيت الصلاة',
      icon: Icons.access_time_filled_rounded,
      route: '/prayer-times',
    ),
    _QuickAccessItem(
      label: 'كيفية الوضوء',
      icon: Icons.water_drop_rounded,
      route: '/wudu',
    ),
    _QuickAccessItem(
      label: 'أذكار دبر الصلاة',
      icon: Icons.format_list_numbered_rounded,
      route: '/post-prayer-dhikr',
    ),
    _QuickAccessItem(
      label: 'دليل الحج والعمرة',
      icon: Icons.flight_takeoff_rounded,
      route: '/hajj-umrah',
    ),
    _QuickAccessItem(
      label: 'ختمة القرآن',
      icon: Icons.bookmark_added_rounded,
      route: '/khatma',
    ),
    _QuickAccessItem(
      label: 'التقويم الإسلامي',
      icon: Icons.calendar_month_rounded,
      route: '/islamic-calendar',
    ),
    _QuickAccessItem(
      label: 'سجلّي',
      icon: Icons.local_fire_department_rounded,
      route: '/azkar-streaks',
    ),
    _QuickAccessItem(
      label: 'تحميل التلاوات',
      icon: Icons.download_for_offline_rounded,
      route: '/quran-downloads',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Row3(items: _row1),
        const SizedBox(height: AppSpacing.sm),
        _Row3(items: _row2),
        const SizedBox(height: AppSpacing.sm),
        _Row2Wide(items: _wideRow),
        const SizedBox(height: AppSpacing.sm),
        _Row3(items: _row4),
        if (_rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          // Remaining tiles in standard 3-up rows.
          for (var i = 0; i < _rest.length; i += 3) ...[
            _Row3(items: _rest.sublist(i, (i + 3).clamp(0, _rest.length))),
            if (i + 3 < _rest.length) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

/// Three-up tile row with consistent spacing and aspect ratio.
class _Row3 extends StatelessWidget {
  final List<_QuickAccessItem> items;
  const _Row3({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.05,
              child: i < items.length
                  ? _QuickTile(item: items[i])
                  : const SizedBox.shrink(),
            ),
          ),
          if (i < 2) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Two-up wide tile row (radio + listen-to-Quran).
class _Row2Wide extends StatelessWidget {
  final List<_QuickAccessItem> items;
  const _Row2Wide({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: SizedBox(
              height: 56,
              child: _WideTile(item: items[i]),
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Standard square tile — green icon, label below.
class _QuickTile extends StatefulWidget {
  final _QuickAccessItem item;
  const _QuickTile({required this.item});

  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1, end: 0.96)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        context.push(widget.item.route);
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primaryDark.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.item.icon,
                size: 30,
                color: AppColors.primaryDark,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: AppColors.primaryInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide horizontal tile — label + small icon side by side.
class _WideTile extends StatefulWidget {
  final _QuickAccessItem item;
  const _WideTile({required this.item});

  @override
  State<_WideTile> createState() => _WideTileState();
}

class _WideTileState extends State<_WideTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1, end: 0.97)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        context.push(widget.item.route);
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primaryDark.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryInk,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                widget.item.icon,
                size: 22,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
