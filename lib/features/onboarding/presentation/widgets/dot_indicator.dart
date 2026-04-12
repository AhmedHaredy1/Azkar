import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Animated dot indicator for onboarding pages.
class DotIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const DotIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: isActive
                ? (isDark ? AppColors.secondaryLight : AppColors.secondary)
                : (isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.3)
                    : AppColors.textSecondary.withValues(alpha: 0.3)),
          ),
        );
      }),
    );
  }
}
