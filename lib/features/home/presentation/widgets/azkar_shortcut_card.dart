import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../providers/home_provider.dart';

/// Time-aware azkar shortcut. Minimal look — white surface, hairline border,
/// green-soft icon bubble. Single restrained accent keeps the home calm.
class AzkarShortcutCard extends ConsumerWidget {
  const AzkarShortcutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(azkarTimeWindowProvider);

    final String label;
    final String subtitle;
    final IconData icon;
    final String categoryId;

    switch (window) {
      case AzkarTimeWindow.morning:
        label = 'أذكار الصباح';
        subtitle = 'ابدأ يومك بذكر الله';
        icon = Icons.wb_sunny_outlined;
        categoryId = 'morning';
      case AzkarTimeWindow.evening:
        label = 'أذكار المساء';
        subtitle = 'لا تنسَ أذكار المساء';
        icon = Icons.nights_stay_outlined;
        categoryId = 'evening';
      case AzkarTimeWindow.sleep:
        label = 'أذكار النوم';
        subtitle = 'اختم يومك بذكر الله';
        icon = Icons.bedtime_outlined;
        categoryId = 'sleep';
      case AzkarTimeWindow.wakeUp:
        label = 'أذكار الاستيقاظ';
        subtitle = 'ابدأ لحظاتك الأولى بحمد الله';
        icon = Icons.brightness_4_outlined;
        categoryId = 'waking_up';
    }

    return GestureDetector(
      onTap: () => context.push('/azkar/$categoryId'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md + 2),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: AppColors.ink3,
            ),
          ],
        ),
      ),
    );
  }
}
