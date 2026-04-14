import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../home/presentation/providers/home_provider.dart';
import '../../settings/presentation/providers/settings_provider.dart';
import 'providers/prayer_times_provider.dart';
import 'widgets/prayer_time_row.dart';

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final countdown = ref.watch(prayerCountdownProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مواقيت الصلاة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const _MonthlyPrayerTimesScreen(),
              ),
            ),
            tooltip: 'التقويم الشهري',
          ),
        ],
      ),
      body: prayerTimesAsync.when(
        data: (prayerTimes) {
          final now = DateTime.now();
          final dateFormatted = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);

          // Build location display text
          String locationText = '';
          if (settings.cityName != null && settings.cityName!.isNotEmpty) {
            locationText = settings.cityName!;
            if (settings.countryName != null && settings.countryName!.isNotEmpty) {
              locationText += ' - ${settings.countryName!}';
            }
          } else if (settings.locationMode == LocationMode.auto) {
            locationText = 'تحديد تلقائي بالموقع';
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Date header with countdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.mosque_outlined,
                        color: AppColors.secondary,
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dateFormatted,
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (locationText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          locationText,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                      // Countdown
                      if (countdown.hasData) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: AppRadius.card,
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${countdown.prayerNameAr} بعد',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                countdown.formattedCountdown,
                                style: GoogleFonts.cairo(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Prayer time rows
                ...prayerTimes.map((pt) => PrayerTimeRow(prayerTime: pt)),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(locationProvider);
                    ref.invalidate(prayerTimesProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(Icons.settings),
                  label: Text('فتح الإعدادات', style: GoogleFonts.cairo()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Monthly Prayer Times Calendar
// ──────────────────────────────────────────────

class _MonthlyPrayerTimesScreen extends ConsumerWidget {
  const _MonthlyPrayerTimesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'ar').format(now);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تقويم $monthName',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      body: locationAsync.when(
        data: (position) {
          final repo = ref.read(prayerTimesRepositoryProvider);
          final settings = ref.watch(settingsProvider);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.primary.withValues(alpha: 0.1),
                  ),
                  columnSpacing: AppSpacing.md,
                  columns: [
                    DataColumn(
                      label: Text(
                        'اليوم',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ...['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء']
                        .map(
                      (name) => DataColumn(
                        label: Text(
                          name,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  rows: List.generate(daysInMonth, (index) {
                    final day = index + 1;
                    final date = DateTime(now.year, now.month, day);
                    final isToday = day == now.day;

                    // Calculate prayer times for this day
                    final times = repo.getPrayerTimesForDate(
                      position.latitude,
                      position.longitude,
                      date,
                      utcOffset: settings.utcOffset,
                    );

                    return DataRow(
                      color: isToday
                          ? WidgetStateProperty.all(
                              AppColors.primary.withValues(alpha: 0.06))
                          : null,
                      cells: [
                        DataCell(Text(
                          ArabicNumberUtils.toEasternArabic(day),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday ? AppColors.primary : AppColors.textPrimary,
                          ),
                        )),
                        ...times.map(
                          (pt) => DataCell(Text(
                            DateFormat('hh:mm', 'ar').format(pt.time),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          )),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            'يرجى تحديد الموقع من الإعدادات أولاً',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
