import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Centered loading indicator with the app's green color.
class LoadingWidget extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const LoadingWidget({
    super.key,
    this.size = 40.0,
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
