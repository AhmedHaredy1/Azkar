import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../theme/tokens.dart';

/// Standard loading state — use in every `AsyncValue.when(loading: ...)`
/// instead of ad-hoc bare [CircularProgressIndicator]s.
class AppLoadingView extends StatelessWidget {
  final String? label;

  const AppLoadingView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              label!,
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.ink3),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standard error state with an optional retry action — use in every
/// `AsyncValue.when(error: ...)` instead of bare `Text('خطأ: $e')`.
class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorView({
    super.key,
    this.message = 'حدث خطأ غير متوقع',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: AppColors.ink3),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, color: AppColors.ink2),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.hairlineStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard empty state — use for lists/screens with no content yet
/// (downloads, favorites, search results...).
class AppEmptyView extends StatelessWidget {
  final String message;
  final String? hint;
  final IconData icon;
  final Widget? action;

  const AppEmptyView({
    super.key,
    required this.message,
    this.hint,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.ink3),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 12, color: AppColors.ink3),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
