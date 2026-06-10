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

/// Hero prayer card — deep green gradient with a restrained gold accent.
/// Shows the next prayer name, exact time, countdown, and a 5-prayer ribbon.
class PrayerCountdownCard extends ConsumerWidget {
  const PrayerCountdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Select only the fields that change once per prayer — the 1-second
    // countdown tick must not rebuild the gradient card and ribbon.
    final hasData =
        ref.watch(prayerCountdownProvider.select((s) => s.hasData));
    final prayerName =
        ref.watch(prayerCountdownProvider.select((s) => s.prayerName));
    final prayerNameAr =
        ref.watch(prayerCountdownProvider.select((s) => s.prayerNameAr));
    final formattedTime =
        ref.watch(prayerCountdownProvider.select((s) => s.formattedTime));
    final prayersAsync = ref.watch(prayerTimesProvider);

    if (!hasData) {
      return const SizedBox.shrink();
    }

    final prayers = prayersAsync.asData?.value ?? const <PrayerTime>[];
    final nextIdx = prayers.indexWhere((p) => p.name == prayerName);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Faint geometric watermark.
            Positioned(
              top: -80,
              right: -80,
              child: GeoWatermark(
                opacity: 0.08,
                color: AppColors.secondaryLight,
                size: 280,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: AppSpacing.md),
                  _nameAndTime(prayerNameAr, formattedTime),
                  const SizedBox(height: AppSpacing.sm),
                  _countdownLine(),
                  const SizedBox(height: AppSpacing.lg),
                  _PrayerRibbon(prayers: prayers, nextIdx: nextIdx),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StarMark(size: 11, color: AppColors.secondaryLight),
        const SizedBox(width: 8),
        Text(
          'الصلاة القادمة',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _nameAndTime(String prayerNameAr, String formattedTime) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          prayerNameAr,
          style: GoogleFonts.cairo(
            fontSize: 44,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            formattedTime,
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: AppColors.secondaryLight,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _countdownLine() {
    return Row(
      children: [
        Text(
          'تبقّى',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(width: 10),
        // Isolated consumer: the 1-second tick rebuilds only this text.
        Consumer(
          builder: (context, ref, _) {
            final countdownText = ref.watch(
              prayerCountdownProvider.select((s) => s.formattedCountdown),
            );
            return Text(
              countdownText,
              style: GoogleFonts.cairo(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PrayerRibbon extends StatelessWidget {
  final List<PrayerTime> prayers;
  final int nextIdx;

  const _PrayerRibbon({required this.prayers, required this.nextIdx});

  @override
  Widget build(BuildContext context) {
    if (prayers.isEmpty) return const SizedBox.shrink();

    return Row(
      children: List.generate(prayers.length, (i) {
        final p = prayers[i];
        final isNext = i == nextIdx;
        final isPast = nextIdx >= 0 && i < nextIdx;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: i == 0 ? 0 : 2),
            child: Container(
              padding: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: isNext
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: isPast ? 0.55 : 1,
                    child: Text(
                      p.nameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.white.withValues(
                          alpha: isNext ? 1 : 0.75,
                        ),
                        fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: isPast ? 0.45 : 1,
                    child: Text(
                      _format(p.time),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (isNext) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  String _format(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '${ArabicNumberUtils.toEasternArabicFromString(h)}:${ArabicNumberUtils.toEasternArabicFromString(m)}';
  }
}
