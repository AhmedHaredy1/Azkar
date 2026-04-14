import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/tokens.dart';

class _QuickAccessItem {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  final Color bgColor;

  const _QuickAccessItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
    required this.bgColor,
  });
}

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  static final _items = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'الأذكار',
      icon: Icons.auto_stories,
      route: '/azkar',
      color: const Color(0xFF1B5E20),
      bgColor: const Color(0xFF1B5E20).withValues(alpha: 0.08),
    ),
    _QuickAccessItem(
      label: 'الأدعية',
      icon: Icons.volunteer_activism,
      route: '/duas',
      color: const Color(0xFF6A1B9A),
      bgColor: const Color(0xFF6A1B9A).withValues(alpha: 0.08),
    ),
    _QuickAccessItem(
      label: 'المصحف الشريف',
      icon: Icons.menu_book,
      route: '/quran',
      color: const Color(0xFF00695C),
      bgColor: const Color(0xFF00695C).withValues(alpha: 0.08),
    ),
    _QuickAccessItem(
      label: 'السبحة',
      icon: Icons.radio_button_checked,
      route: '/sebha',
      color: const Color(0xFFE65100),
      bgColor: const Color(0xFFE65100).withValues(alpha: 0.08),
    ),
    _QuickAccessItem(
      label: 'مواقيت الصلاة',
      icon: Icons.access_time_filled,
      route: '/prayer-times',
      color: const Color(0xFF1565C0),
      bgColor: const Color(0xFF1565C0).withValues(alpha: 0.08),
    ),
    _QuickAccessItem(
      label: 'اتجاه القبلة',
      icon: Icons.explore,
      route: '/qibla',
      color: const Color(0xFFC62828),
      bgColor: const Color(0xFFC62828).withValues(alpha: 0.08),
    ),
    _QuickAccessItem(
      label: 'استمع للقرآن',
      icon: Icons.headphones,
      route: '/quran-listen',
      color: const Color(0xFF00838F),
      bgColor: const Color(0xFF00838F).withValues(alpha: 0.08),
    ),
    _QuickAccessItem(
      label: 'البث المباشر',
      icon: Icons.radio,
      route: '/live-radio',
      color: const Color(0xFF4E342E),
      bgColor: const Color(0xFF4E342E).withValues(alpha: 0.08),
    ),
    _QuickAccessItem(
      label: 'دليل الحج والعمرة',
      icon: Icons.mosque,
      route: '/hajj-umrah',
      color: const Color(0xFF827717),
      bgColor: const Color(0xFF827717).withValues(alpha: 0.08),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.6,
      children: _items.map((item) => _QuickAccessCard(item: item)).toList(),
    );
  }
}

class _QuickAccessCard extends StatefulWidget {
  final _QuickAccessItem item;

  const _QuickAccessCard({required this.item});

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        context.push(widget.item.route);
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: widget.item.color.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.item.color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.item.bgColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.md),
                  ),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 26,
                  color: widget.item.color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
