import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';

/// A single onboarding page with an icon, title, and description.
class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color iconBackgroundColor;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor = AppColors.secondary,
    this.iconBackgroundColor = const Color(0x1AD4A017), // secondary 10%
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Decorative circle with icon
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.primaryLight.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: isDark
                    ? AppColors.primaryLight.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.primaryLight.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  icon,
                  size: 56,
                  color: isDark ? AppColors.secondaryLight : AppColors.secondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Decorative separator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      isDark ? AppColors.secondaryLight : AppColors.secondary,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.star,
                size: 10,
                color: isDark ? AppColors.secondaryLight : AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 30,
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? AppColors.secondaryLight : AppColors.secondary,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.7,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
