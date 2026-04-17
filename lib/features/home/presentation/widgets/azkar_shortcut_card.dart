import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../providers/home_provider.dart';

class AzkarShortcutCard extends ConsumerWidget {
  const AzkarShortcutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(azkarTimeWindowProvider);

    // Pick the category that matches the current moment of the day.
    final String label;
    final String subtitle;
    final IconData icon;
    final String categoryId;
    final Color accentColor;

    switch (window) {
      case AzkarTimeWindow.morning:
        label = 'أذكار الصباح';
        subtitle = 'ابدأ يومك بذكر الله';
        icon = Icons.wb_sunny_outlined;
        categoryId = 'morning';
        accentColor = const Color(0xFFF57F17); // warm amber
      case AzkarTimeWindow.evening:
        label = 'أذكار المساء';
        subtitle = 'لا تنسَ أذكار المساء';
        icon = Icons.nights_stay_outlined;
        categoryId = 'evening';
        accentColor = const Color(0xFF5C6BC0); // indigo
      case AzkarTimeWindow.sleep:
        label = 'أذكار النوم';
        subtitle = 'اختم يومك بذكر الله';
        icon = Icons.bedtime_outlined;
        categoryId = 'sleep';
        accentColor = const Color(0xFF3949AB); // deep indigo
      case AzkarTimeWindow.wakeUp:
        label = 'أذكار الاستيقاظ';
        subtitle = 'ابدأ لحظاتك الأولى بحمد الله';
        icon = Icons.brightness_4_outlined;
        categoryId = 'waking_up';
        accentColor = const Color(0xFF00897B); // teal
    }

    return GestureDetector(
      onTap: () => context.push('/azkar/$categoryId'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              accentColor.withValues(alpha: 0.12),
              accentColor.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 26,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: accentColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
