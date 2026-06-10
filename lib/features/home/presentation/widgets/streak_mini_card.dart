import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../../azkar_streaks/presentation/providers/azkar_streaks_provider.dart';

/// 14-day azkar streak heatmap card.
/// Matches the Claude Design prototype's `StreakMini` — LTR grid of 14 cells
/// with a 4-step green tone scale based on morning/evening completion per day.
class StreakMiniCard extends ConsumerWidget {
  const StreakMiniCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaks = ref.watch(azkarStreaksProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final values = List<int>.generate(14, (i) {
      final day = today.subtract(Duration(days: 13 - i));
      final m = streaks.didMorning(day);
      final e = streaks.didEvening(day);
      if (m && e) return 4;
      if (m || e) return 2;
      return 0;
    });

    return GestureDetector(
      onTap: () => context.push('/azkar-streaks'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.hairline, width: 1),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'سلسلة الأذكار',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      ArabicNumberUtils.toEasternArabic(streaks.currentStreak),
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'يوم',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  for (int i = 0; i < values.length; i++) ...[
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _tone(values[i]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    if (i != values.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tone(int v) {
    switch (v) {
      case 0:
        return AppColors.surfaceSunk;
      case 1:
        return const Color(0xFFDCE6DC);
      case 2:
        return const Color(0xFFB9D0BB);
      case 3:
        return const Color(0xFF6FA074);
      default:
        return AppColors.primary;
    }
  }
}
