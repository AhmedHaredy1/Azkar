import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/models/prayer_time.dart';

class PrayerTimeRow extends StatelessWidget {
  final PrayerTime prayerTime;
  final bool isPast;

  const PrayerTimeRow({
    super.key,
    required this.prayerTime,
    this.isPast = false,
  });

  IconData _icon() {
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

  String _subtitle() {
    switch (prayerTime.name) {
      case 'Fajr':
        return 'قبل شروق الشمس';
      case 'Sunrise':
        return 'الشروق';
      case 'Dhuhr':
        return 'منتصف النهار';
      case 'Asr':
        return 'ما قبل الغروب';
      case 'Maghrib':
        return 'غروب الشمس';
      case 'Isha':
        return 'بعد المغرب';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a', 'ar').format(prayerTime.time);
    final active = prayerTime.isNext;

    final rowColor = active ? AppColors.primarySoft : AppColors.surface;
    final tileColor = active
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.surfaceSunk;
    final iconColor =
        active ? AppColors.primary : (isPast ? AppColors.ink3 : AppColors.ink2);
    final nameColor =
        active ? AppColors.primary : (isPast ? AppColors.ink3 : AppColors.ink);
    final timeColor = active ? AppColors.primary : AppColors.ink;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: active ? AppColors.hairlineStrong : AppColors.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(_icon(), color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      prayerTime.nameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'التالي',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: timeColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Icon(
            active
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined,
            size: 18,
            color: active ? AppColors.primary : AppColors.ink3,
          ),
        ],
      ),
    );
  }
}
