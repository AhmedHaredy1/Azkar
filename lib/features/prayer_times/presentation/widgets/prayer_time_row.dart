import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/models/prayer_time.dart';

class PrayerTimeRow extends StatelessWidget {
  final PrayerTime prayerTime;

  const PrayerTimeRow({super.key, required this.prayerTime});

  IconData _getIcon() {
    switch (prayerTime.name) {
      case 'Fajr':
        return Icons.wb_twilight;
      case 'Sunrise':
        return Icons.wb_sunny_outlined;
      case 'Dhuhr':
        return Icons.wb_sunny;
      case 'Asr':
        return Icons.sunny_snowing;
      case 'Maghrib':
        return Icons.nights_stay_outlined;
      case 'Isha':
        return Icons.dark_mode_outlined;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormatted = DateFormat('hh:mm a', 'ar').format(prayerTime.time);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      decoration: BoxDecoration(
        color: prayerTime.isNext
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: prayerTime.isNext
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.cardBorder,
          width: prayerTime.isNext ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: prayerTime.isNext
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              _getIcon(),
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Text(
                  prayerTime.nameAr,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: prayerTime.isNext ? FontWeight.bold : FontWeight.w500,
                    color: prayerTime.isNext ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (prayerTime.isNext) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'التالي',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            timeFormatted,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: prayerTime.isNext ? FontWeight.bold : FontWeight.w500,
              color: prayerTime.isNext ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
