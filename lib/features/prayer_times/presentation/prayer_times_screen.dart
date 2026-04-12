import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../home/presentation/providers/home_provider.dart';
import '../../settings/presentation/providers/settings_provider.dart';
import 'providers/prayer_times_provider.dart';
import 'widgets/prayer_time_row.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.location_city),
            onPressed: () => _showCityPicker(context),
            tooltip: 'تغيير المدينة',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showMonthlyCalendar(context),
            tooltip: 'التقويم الشهري',
          ),
        ],
      ),
      body: prayerTimesAsync.when(
        data: (prayerTimes) {
          final now = DateTime.now();
          final dateFormatted = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Date header with countdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                      const SizedBox(height: 4),
                      if (settings.cityName != null && settings.cityName!.isNotEmpty)
                        Text(
                          settings.cityName!,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        )
                      else
                        ref.watch(locationProvider).when(
                              data: (pos) => Text(
                                '${pos.latitude.toStringAsFixed(2)}°, ${pos.longitude.toStringAsFixed(2)}°',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              loading: () => const SizedBox(),
                              error: (_, _) => const SizedBox(),
                            ),
                      // Countdown
                      if (countdown.hasData) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
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
                const SizedBox(height: 12),
                // Prayer time rows
                ...prayerTimes.map((pt) => PrayerTimeRow(prayerTime: pt)),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(locationProvider);
                    ref.invalidate(prayerTimesProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showCityPicker(context),
                  icon: const Icon(Icons.location_city),
                  label: const Text('اختيار مدينة يدوياً'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CityPickerSheet(
        onCitySelected: (city) {
          ref.read(settingsProvider.notifier).setLocation(
                city.lat,
                city.lng,
                city: city.nameAr,
              );
          ref.invalidate(prayerTimesProvider);
          ref.invalidate(nextPrayerProvider);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showMonthlyCalendar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _MonthlyPrayerTimesScreen(),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// City Model & Picker
// ──────────────────────────────────────────────

class _City {
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;

  const _City(this.nameAr, this.nameEn, this.lat, this.lng);
}

const _majorCities = [
  _City('مكة المكرمة', 'Mecca', 21.4225, 39.8262),
  _City('المدينة المنورة', 'Medina', 24.4672, 39.6112),
  _City('الرياض', 'Riyadh', 24.7136, 46.6753),
  _City('جدة', 'Jeddah', 21.5433, 39.1728),
  _City('القاهرة', 'Cairo', 30.0444, 31.2357),
  _City('الإسكندرية', 'Alexandria', 31.2001, 29.9187),
  _City('دبي', 'Dubai', 25.2048, 55.2708),
  _City('أبو ظبي', 'Abu Dhabi', 24.4539, 54.3773),
  _City('الدوحة', 'Doha', 25.2854, 51.5310),
  _City('الكويت', 'Kuwait City', 29.3759, 47.9774),
  _City('المنامة', 'Manama', 26.2285, 50.5860),
  _City('مسقط', 'Muscat', 23.5880, 58.3829),
  _City('عمّان', 'Amman', 31.9454, 35.9284),
  _City('بيروت', 'Beirut', 33.8938, 35.5018),
  _City('بغداد', 'Baghdad', 33.3152, 44.3661),
  _City('الخرطوم', 'Khartoum', 15.5007, 32.5599),
  _City('تونس', 'Tunis', 36.8065, 10.1815),
  _City('الرباط', 'Rabat', 34.0209, -6.8416),
  _City('الجزائر', 'Algiers', 36.7538, 3.0588),
  _City('إسطنبول', 'Istanbul', 41.0082, 28.9784),
  _City('أنقرة', 'Ankara', 39.9334, 32.8597),
  _City('جاكرتا', 'Jakarta', -6.2088, 106.8456),
  _City('كوالالمبور', 'Kuala Lumpur', 3.1390, 101.6869),
  _City('لندن', 'London', 51.5074, -0.1278),
  _City('باريس', 'Paris', 48.8566, 2.3522),
  _City('نيويورك', 'New York', 40.7128, -74.0060),
  _City('طرابلس', 'Tripoli', 32.8872, 13.1913),
  _City('صنعاء', 'Sanaa', 15.3694, 44.1910),
  _City('دمشق', 'Damascus', 33.5138, 36.2765),
  _City('المنصورة', 'Mansoura', 31.0409, 31.3785),
];

class _CityPickerSheet extends StatefulWidget {
  final void Function(_City city) onCitySelected;

  const _CityPickerSheet({required this.onCitySelected});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _searchQuery = '';

  List<_City> get _filteredCities {
    if (_searchQuery.isEmpty) return _majorCities;
    return _majorCities
        .where((c) =>
            c.nameAr.contains(_searchQuery) ||
            c.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'اختر مدينتك',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'ابحث عن مدينة...',
                  hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.cairo(fontSize: 15),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredCities.length,
                itemBuilder: (context, index) {
                  final city = _filteredCities[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    title: Text(
                      city.nameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      city.nameEn,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () => widget.onCitySelected(city),
                  );
                },
              ),
            ),
          ],
        );
      },
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

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.primary.withValues(alpha: 0.1),
                  ),
                  columnSpacing: 12,
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
            'يرجى تفعيل الموقع أولاً',
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
