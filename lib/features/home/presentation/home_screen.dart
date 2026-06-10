import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import 'widgets/azkar_shortcut_card.dart';
import 'widgets/daily_ayah_card.dart';
import 'widgets/home_hero_card.dart';
import 'widgets/quick_access_grid.dart';
import 'widgets/streak_mini_card.dart';

/// Home screen — two-zone layout matching the Rafeeq Al-Muslim design.
///
/// Top zone (cream): hero card (location + dates + logo + next prayer +
/// prayer chips) and the time-aware azkar shortcut card.
/// Bottom zone (deep green): الأقسام grid + Daily Ayah + Streak — all
/// sections kept and reachable by scrolling.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top zone: cream parchment ──
              Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    HomeHeroCard(),
                    SizedBox(height: AppSpacing.md),
                    AzkarShortcutCard(),
                  ],
                ),
              ),

              // ── Bottom zone: deep-green sections ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xxl),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _OnGreenSectionHeader(title: 'الأقسام'),
                    const SizedBox(height: AppSpacing.sm),
                    const QuickAccessGrid(),

                    const SizedBox(height: AppSpacing.lg),
                    const _OnGreenSectionHeader(title: 'آية اليوم'),
                    const SizedBox(height: AppSpacing.sm),
                    const DailyAyahCard(),

                    const SizedBox(height: AppSpacing.lg),
                    _OnGreenSectionHeader(
                      title: 'نشاطك',
                      action: 'عرض الكل',
                      onAction: () => context.push('/azkar-streaks'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const StreakMiniCard(),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header for the green-bg zone — cream/gold title text.
class _OnGreenSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _OnGreenSectionHeader({
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryLight,
              letterSpacing: -0.1,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                child: Text(
                  action!,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
