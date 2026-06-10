import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
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

  static const _methodNames = <String, String>{
    'UmmAlQura': 'أم القرى',
    'Egyptian': 'الهيئة المصرية',
    'MuslimWorldLeague': 'رابطة العالم الإسلامي',
    'Karachi': 'جامعة العلوم الإسلامية — كراتشي',
    'NorthAmerica': 'أمريكا الشمالية',
    'Dubai': 'دبي',
    'Kuwait': 'الكويت',
    'Qatar': 'قطر',
    'Singapore': 'سنغافورة',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'مواقيت الصلاة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, size: 22),
            color: AppColors.ink2,
            tooltip: 'التقويم الشهري',
            onPressed: () => context.push('/prayer-times-monthly'),
          ),
        ],
      ),
      body: prayerTimesAsync.when(
        data: (prayerTimes) {
          final now = DateTime.now();
          final hijri = HijriCalendar.now();

          String? locationText;
          if (settings.cityName != null && settings.cityName!.isNotEmpty) {
            locationText = settings.cityName!;
            if (settings.countryName != null &&
                settings.countryName!.isNotEmpty) {
              locationText = '$locationText، ${settings.countryName!}';
            }
          } else if (settings.locationMode == LocationMode.auto) {
            locationText = 'تحديد تلقائي بالموقع';
          }

          final methodLabel =
              _methodNames[settings.calculationMethod] ?? 'أم القرى';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                _DateCard(
                  hijri: hijri,
                  gregorian: now,
                  locationText: locationText,
                ),
                const SizedBox(height: AppSpacing.md),
                ...prayerTimes.map((pt) {
                  final isPast = pt.time.isBefore(now) && !pt.isNext;
                  return PrayerTimeRow(prayerTime: pt, isPast: isPast);
                }),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg + 4),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          size: 14, color: AppColors.ink3),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'طريقة الحساب: $methodLabel',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off_outlined,
                    size: 48, color: AppColors.ink3),
                const SizedBox(height: AppSpacing.md),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.ink2,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(locationProvider);
                    ref.invalidate(prayerTimesProvider);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.hairlineStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm + 2,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text('فتح الإعدادات', style: GoogleFonts.cairo()),
                  style: TextButton.styleFrom(foregroundColor: AppColors.ink2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateCard extends ConsumerWidget {
  final HijriCalendar hijri;
  final DateTime gregorian;
  final String? locationText;

  const _DateCard({
    required this.hijri,
    required this.gregorian,
    required this.locationText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow selects: these only change when the upcoming prayer itself
    // changes, so the card stays out of the 1-second tick.
    final hasCountdown =
        ref.watch(prayerCountdownProvider.select((s) => s.hasData));
    final nextPrayerNameAr =
        ref.watch(prayerCountdownProvider.select((s) => s.prayerNameAr));
    final gregorianFmt =
        DateFormat('EEEE، d MMMM yyyy', 'ar').format(gregorian);
    final hijriFmt =
        '${ArabicNumberUtils.toEasternArabic(hijri.hDay)} ${hijri.longMonthName} ${ArabicNumberUtils.toEasternArabic(hijri.hYear)}هـ';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          Text(
            hijriFmt,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            gregorianFmt,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.ink3,
            ),
          ),
          if (locationText != null) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.ink3),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    locationText!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (hasCountdown) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 1,
              color: AppColors.hairline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$nextPrayerNameAr بعد',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.ink3,
              ),
            ),
            const SizedBox(height: 4),
            // Isolated consumer: the 1-second tick rebuilds only this text,
            // not the date card or the prayer rows above it.
            Consumer(
              builder: (context, ref, _) {
                final countdownText = ref.watch(
                  prayerCountdownProvider.select((s) => s.formattedCountdown),
                );
                return Text(
                  countdownText,
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Monthly Prayer Times Calendar
// ──────────────────────────────────────────────

class MonthlyPrayerTimesScreen extends ConsumerWidget {
  const MonthlyPrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'ar').format(now);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تقويم $monthName',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
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
                    AppColors.primarySoft,
                  ),
                  columnSpacing: AppSpacing.md,
                  columns: [
                    DataColumn(
                      label: Text(
                        'اليوم',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ...[
                      'الفجر',
                      'الشروق',
                      'الظهر',
                      'العصر',
                      'المغرب',
                      'العشاء'
                    ].map(
                      (name) => DataColumn(
                        label: Text(
                          name,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
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

                    final times = repo.getPrayerTimesForDate(
                      position.latitude,
                      position.longitude,
                      date,
                      utcOffset: settings.utcOffset,
                    );

                    return DataRow(
                      color: isToday
                          ? WidgetStateProperty.all(AppColors.primarySoft)
                          : null,
                      cells: [
                        DataCell(Text(
                          ArabicNumberUtils.toEasternArabic(day),
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color:
                                isToday ? AppColors.primary : AppColors.ink,
                          ),
                        )),
                        ...times.map(
                          (pt) => DataCell(Text(
                            DateFormat('hh:mm', 'ar').format(pt.time),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.ink,
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
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            'يرجى تحديد الموقع من الإعدادات أولاً',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
