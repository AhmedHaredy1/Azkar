import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../domain/nusuk_type.dart';

/// Overall-progress card shown at the top of the active session: percent bar,
/// current step name, and remaining-step count.
class NusukProgressHeader extends StatelessWidget {
  final NusukType type;
  final int completedCount;
  final int totalCount;
  final String currentStepTitle;

  const NusukProgressHeader({
    super.key,
    required this.type,
    required this.completedCount,
    required this.totalCount,
    required this.currentStepTitle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final fraction = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final percent = (fraction * 100).round();
    final remaining = (totalCount - completedCount).clamp(0, totalCount);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'تقدّم ${type.arabicName}',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${ArabicNumberUtils.toEasternArabic(percent)}٪',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: AppColors.surfaceSunk,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.adjust_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'الخطوة الحالية: $currentStepTitle',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'المتبقي: ${ArabicNumberUtils.toEasternArabic(remaining)}',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
