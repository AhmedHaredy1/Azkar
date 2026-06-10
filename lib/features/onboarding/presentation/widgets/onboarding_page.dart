import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../../../core/widgets/ornaments.dart';

class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int stepIndex;
  final int totalSteps;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.stepIndex = 0,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    final stepLabel =
        'خطوة ${ArabicNumberUtils.toEasternArabic(stepIndex + 1)} من ${ArabicNumberUtils.toEasternArabic(totalSteps)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          AspectRatio(
            aspectRatio: 1 / 0.8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: GeoWatermark(
                        size: 300,
                        color: AppColors.primary,
                        opacity: 0.12,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, size: 42, color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          stepLabel,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.md),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.3,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            description,
            style: GoogleFonts.cairo(
              fontSize: 15,
              height: 1.8,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
