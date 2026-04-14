import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import 'providers/home_provider.dart';
import 'widgets/azkar_shortcut_card.dart';
import 'widgets/daily_ayah_card.dart';
import 'widgets/prayer_countdown_card.dart';
import 'widgets/quick_access_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    final hijriDate = ref.watch(hijriDateProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingCard(greeting: greeting, hijriDate: hijriDate),

              const SizedBox(height: AppSpacing.lg),
              const PrayerCountdownCard(),

              const SizedBox(height: AppSpacing.lg),
              const AzkarShortcutCard(),

              const SizedBox(height: AppSpacing.xl),
              _SectionHeader(title: 'الأقسام'),
              const SizedBox(height: AppSpacing.md),
              const QuickAccessGrid(),

              const SizedBox(height: AppSpacing.xl),
              const DailyAyahCard(),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final GreetingState greeting;
  final HijriDateState hijriDate;
  const _GreetingCard({required this.greeting, required this.hijriDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mosque_rounded,
                  color: AppColors.secondary, size: 28),
              const Spacer(),
              Text(
                'حصن المسلم',
                style: GoogleFonts.amiri(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            greeting.greeting,
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            greeting.subtitle,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.all(Radius.circular(AppRadius.md)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  hijriDate.hijriFormatted,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    hijriDate.gregorianFormatted,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
