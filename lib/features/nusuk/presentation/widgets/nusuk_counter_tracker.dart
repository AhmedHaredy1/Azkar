import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/arabic_number_utils.dart';

/// Interactive tally for counter steps (Tawaf/Saʿy circuits, Jamarat pebbles).
/// Shows «الشوط ٣ من ٧», a row of segment dots, the remaining count, and a big
/// increment button. The parent auto-completes the step at [target].
class NusukCounterTracker extends StatelessWidget {
  /// Repetitions already done.
  final int current;
  final int target;

  /// Singular unit, e.g. «شوط» / «حصاة».
  final String unit;
  final VoidCallback onIncrement;

  const NusukCounterTracker({
    super.key,
    required this.current,
    required this.target,
    required this.unit,
    required this.onIncrement,
  });

  String get _defLabel => 'ال$unit'; // الشوط / الحصاة
  String get _accLabel {
    switch (unit) {
      case 'شوط':
        return 'شوطاً';
      case 'حصاة':
        return 'حصاة';
      default:
        return unit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final remaining = (target - current).clamp(0, target);
    final ordinal = (current + 1).clamp(1, target);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Segment dots
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(target, (i) {
              final filled = i < current;
              return Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? primary : AppColors.surface,
                  border: Border.all(
                    color: filled ? primary : AppColors.hairlineStrong,
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$_defLabel ${ArabicNumberUtils.toEasternArabic(ordinal)} '
            'من ${ArabicNumberUtils.toEasternArabic(target)}',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'المتبقي: ${ArabicNumberUtils.toEasternArabic(remaining)}',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'أتممت $_accLabel',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
