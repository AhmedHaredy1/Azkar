import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../providers/home_provider.dart';

class DailyAyahCard extends ConsumerWidget {
  const DailyAyahCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahAsync = ref.watch(dailyAyahProvider);

    return ayahAsync.when(
      data: (ayah) {
        if (!ayah.hasData) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_stories,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'آية اليوم',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'سورة ${ayah.surahName}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Decorative top divider
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                ayah.ayahText,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  height: 2.0,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Decorative bottom divider
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '﴿ ${ayah.surahName} : ${ayah.ayahNumber} ﴾',
                style: GoogleFonts.amiri(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.secondary,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
