import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Greeting Card with Hijri Date ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.mosque_outlined,
                          color: AppColors.secondary,
                          size: 28,
                        ),
                        const Spacer(),
                        Text(
                          'حصن المسلم',
                          style: GoogleFonts.amiri(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      greeting.greeting,
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greeting.subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Hijri & Gregorian dates
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hijriDate.hijriFormatted,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Text(
                              hijriDate.gregorianFormatted,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Next Prayer Countdown ──
              const PrayerCountdownCard(),

              const SizedBox(height: 20),

              // ── Morning/Evening Azkar Shortcut ──
              const AzkarShortcutCard(),

              const SizedBox(height: 24),

              // ── Sections Title ──
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'الأقسام',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Quick Access Grid ──
              const QuickAccessGrid(),

              const SizedBox(height: 24),

              // ── Daily Ayah Card ──
              const DailyAyahCard(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
