import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

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
      label: 'القرآن الكريم',
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
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
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
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
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
              const SizedBox(width: 14),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.item.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 26,
                  color: widget.item.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
