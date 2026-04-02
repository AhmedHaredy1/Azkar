import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import 'providers/prayer_times_provider.dart';
import 'widgets/prayer_time_row.dart';

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مواقيت الصلاة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      body: prayerTimesAsync.when(
        data: (prayerTimes) {
          final now = DateTime.now();
          final dateFormatted = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Date header
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
                      ref.watch(locationProvider).when(
                            data: (pos) => Text(
                              '${pos.latitude.toStringAsFixed(2)}°, ${pos.longitude.toStringAsFixed(2)}°',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
