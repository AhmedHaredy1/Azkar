import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../../../core/widgets/ornaments.dart';
import '../../../prayer_times/domain/models/prayer_time.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../providers/home_provider.dart';

/// Cream-parchment hero card matching the Rafeeq Al-Muslim home design.
/// Combines location, dual date (Gregorian + Hijri), brand logo,
/// next-prayer countdown, and a 6-prayer chip strip with the active
/// prayer highlighted in gold.
class HomeHeroCard extends ConsumerWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijri = ref.watch(hijriDateProvider);
    // Watch only the next-prayer name (changes once per prayer) — the
    // 1-second countdown ticker must not rebuild the whole hero card.
    final nextPrayerName =
        ref.watch(prayerCountdownProvider.select((s) => s.prayerName));
    final prayersAsync = ref.watch(prayerTimesProvider);
    final location = ref.watch(locationProvider);
    final cityLabel = ref.watch(cityLabelProvider);

    final hasFix = location.asData?.value != null;
    final resolved = cityLabel.asData?.value;
    final locationLabel = resolved != null && resolved.hasAny
        ? resolved.display
        : (hasFix ? 'الموقع الحالي' : '…');

    final prayers = prayersAsync.asData?.value ?? const <PrayerTime>[];
    final nextIdx = prayers.indexWhere((p) => p.name == nextPrayerName);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondarySoft,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.45),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryDark.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: GeoWatermark(
                opacity: 0.07,
                color: AppColors.secondaryDark,
                size: 220,
              ),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: GeoWatermark(
                opacity: 0.05,
                color: AppColors.primary,
                size: 200,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md + 2,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopRow(
                    locationLabel: locationLabel,
                    gregorian: hijri.gregorianFormatted,
                    hijri: hijri.hijriFormatted,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _MiddleRow(),
                  const SizedBox(height: AppSpacing.md),
                  _PrayerChipsStrip(prayers: prayers, nextIdx: nextIdx),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final String locationLabel;
  final String gregorian;
  final String hijri;

  const _TopRow({
    required this.locationLabel,
    required this.gregorian,
    required this.hijri,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start (right in RTL): location pill — but mockup shows location on
        // the LEFT visually. In RTL, "left" is the END of the row, so we put
        // location pill last. To make code intent obvious we use a plain Row
        // and rely on the surrounding RTL Directionality.
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gregorian,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  color: AppColors.primaryInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hijri,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.primaryInk,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiddleRow extends ConsumerWidget {
  const _MiddleRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Name and time change at most once per prayer; only the countdown line
    // below subscribes to the per-second tick.
    final hasData =
        ref.watch(prayerCountdownProvider.select((s) => s.hasData));
    final prayerNameAr =
        ref.watch(prayerCountdownProvider.select((s) => s.prayerNameAr));
    final formattedTime =
        ref.watch(prayerCountdownProvider.select((s) => s.formattedTime));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo on the start (= right side visually in RTL — matches mockup
        // where the circular emblem sits on the right of the prayer info).
        // Wait: mockup actually has logo on the LEFT visually. In RTL, that's
        // the END. So we put logo last and prayer info first.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الصلاة القادمة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.ink2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        hasData ? prayerNameAr : '—',
                        style: GoogleFonts.cairo(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryInk,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      formattedTime,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'تبقّى',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    // Isolated consumer: the 1-second tick rebuilds only this
                    // text, not the rest of the hero card.
                    child: Consumer(
                      builder: (context, ref, _) {
                        final countdownText = ref.watch(
                          prayerCountdownProvider
                              .select((s) => s.formattedCountdown),
                        );
                        return Text(
                          countdownText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.secondary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryDark.withValues(alpha: 0.20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrayerChipsStrip extends StatelessWidget {
  final List<PrayerTime> prayers;
  final int nextIdx;

  const _PrayerChipsStrip({required this.prayers, required this.nextIdx});

  @override
  Widget build(BuildContext context) {
    if (prayers.isEmpty) return const SizedBox(height: 64);
    return Row(
      children: List.generate(prayers.length, (i) {
        final p = prayers[i];
        final isNext = i == nextIdx;
        return Expanded(
          child: _PrayerChip(prayer: p, isNext: isNext),
        );
      }),
    );
  }
}

class _PrayerChip extends StatelessWidget {
  final PrayerTime prayer;
  final bool isNext;

  const _PrayerChip({required this.prayer, required this.isNext});

  IconData get _icon {
    switch (prayer.name) {
      case 'Fajr':
        return Icons.wb_twilight_rounded;
      case 'Sunrise':
        return Icons.wb_sunny_outlined;
      case 'Dhuhr':
        return Icons.wb_sunny_rounded;
      case 'Asr':
        return Icons.brightness_5_rounded;
      case 'Maghrib':
        return Icons.brightness_3_rounded;
      case 'Isha':
        return Icons.bedtime_rounded;
    }
    return Icons.access_time_rounded;
  }

  String _formatTime(DateTime t) {
    final h = t.hour;
    final m = t.minute;
    final period = h >= 12 ? 'م' : 'ص';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final hh = ArabicNumberUtils.toEasternArabicFromString(hour12.toString());
    final mm = ArabicNumberUtils.toEasternArabicFromString(
      m.toString().padLeft(2, '0'),
    );
    return '$hh:$mm $period';
  }

  @override
  Widget build(BuildContext context) {
    final activeBg = AppColors.secondary;
    final activeFg = Colors.white;
    final inactiveFg = AppColors.primaryInk;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: isNext ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppColors.secondaryDark.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: 16,
            color: isNext ? activeFg : AppColors.secondaryDark,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              prayer.nameAr,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isNext ? activeFg : inactiveFg,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatTime(prayer.time),
              style: GoogleFonts.cairo(
                fontSize: 9,
                color: isNext
                    ? activeFg.withValues(alpha: 0.92)
                    : AppColors.ink3,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
