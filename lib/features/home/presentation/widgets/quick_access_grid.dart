import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class _QuickAccessItem {
  final String label;
  final IconData icon;
  final String route;
  final Color color;

  const _QuickAccessItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
  });
}

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  static const _items = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'الأذكار',
      icon: Icons.auto_stories,
      route: '/azkar',
      color: AppColors.primary,
    ),
    _QuickAccessItem(
      label: 'الأدعية',
      icon: Icons.volunteer_activism,
      route: '/duas',
      color: Color(0xFF6A1B9A),
    ),
    _QuickAccessItem(
      label: 'القرآن',
      icon: Icons.menu_book,
      route: '/quran',
      color: Color(0xFF00695C),
    ),
    _QuickAccessItem(
      label: 'السبحة',
      icon: Icons.radio_button_checked,
      route: '/sebha',
      color: Color(0xFFE65100),
    ),
    _QuickAccessItem(
      label: 'مواقيت الصلاة',
      icon: Icons.access_time_filled,
      route: '/prayer-times',
      color: Color(0xFF1565C0),
    ),
    _QuickAccessItem(
      label: 'القبلة',
      icon: Icons.explore,
      route: '/qibla',
      color: Color(0xFFC62828),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: _items.map((item) => _QuickAccessCard(item: item)).toList(),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final _QuickAccessItem item;

  const _QuickAccessCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  size: 28,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
