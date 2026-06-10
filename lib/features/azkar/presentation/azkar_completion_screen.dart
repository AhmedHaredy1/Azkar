import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../azkar_streaks/presentation/providers/azkar_streaks_provider.dart';

class AzkarCompletionScreen extends ConsumerStatefulWidget {
  final String categoryName;

  const AzkarCompletionScreen({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<AzkarCompletionScreen> createState() =>
      _AzkarCompletionScreenState();
}

class _AzkarCompletionScreenState extends ConsumerState<AzkarCompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Record streak for morning/evening completions.
    final kind = azkarKindFromName(widget.categoryName);
    if (kind != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(azkarStreaksProvider.notifier).markCompleted(kind);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _shareCompletion() {
    final text =
        'الحمد لله، أتممت ${widget.categoryName} ✅\n\nتطبيق رفيق المسلم';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated check circle
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.success.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _checkAnimation,
                        child: const Icon(
                          Icons.check_circle,
                          size: 72,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Main congratulation text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'أحسنت!',
                        style: GoogleFonts.cairo(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'أتممت ${widget.categoryName}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'تقبّل الله منك',
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          color: AppColors.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Action buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Share button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _shareCompletion,
                          icon: const Icon(Icons.share_outlined, size: 22),
                          label: Text(
                            'مشاركة',
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.card,
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Back to home button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.home_outlined, size: 22),
                          label: Text(
                            'العودة للرئيسية',
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.card,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
