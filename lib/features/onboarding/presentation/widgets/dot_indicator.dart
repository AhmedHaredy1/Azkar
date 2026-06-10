import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: isActive ? AppColors.primary : AppColors.hairlineStrong,
          ),
        );
      }),
    );
  }
}
