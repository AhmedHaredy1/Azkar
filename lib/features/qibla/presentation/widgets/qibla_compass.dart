import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';

class QiblaCompass extends StatelessWidget {
  /// The angle in radians to rotate toward Qibla direction.
  final double angle;

  const QiblaCompass({super.key, required this.angle});

  @override
  Widget build(BuildContext context) {
    final degrees = (angle * 180 / pi) % 360;
    final signedOffset = degrees > 180 ? degrees - 360 : degrees;
    final isFacingQibla = signedOffset.abs() <= 5;
    final indicatorColor =
        isFacingQibla ? AppColors.success : AppColors.primary;

    // Direction hint for the user.
    String directionHint;
    if (isFacingQibla) {
      directionHint = 'أنت تواجه القبلة ✓';
    } else if (signedOffset > 0 && signedOffset <= 180) {
      directionHint = 'أدر يميناً →';
    } else {
      directionHint = '← أدر يساراً';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status banner
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(isFacingQibla),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: indicatorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              directionHint,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: indicatorColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Compass
        SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Static outer ring ──
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: indicatorColor.withValues(alpha: 0.2),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: indicatorColor.withValues(alpha: 0.08),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // ── Static compass face (tick marks only, no cardinal text) ──
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Tick marks (static)
                    ...List.generate(36, (i) {
                      final tickAngle = i * 10 * pi / 180;
                      final isMain = i % 9 == 0;
                      return Transform.rotate(
                        angle: tickAngle,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: isMain ? 2.5 : 1,
                            height: isMain ? 16 : 8,
                            color: isMain
                                ? AppColors.primary.withValues(alpha: 0.6)
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.25),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // ── Rotating Kaaba pointer (always points toward Qibla) ──
              AnimatedRotation(
                turns: angle / (2 * pi),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Arrow + Kaaba at the top of the compass, pointing out
                    Transform.translate(
                      offset: const Offset(0, -70),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Kaaba image (always visible)
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: indicatorColor
                                      .withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/kaaba.png',
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Arrow pointing from center toward Kaaba
                          Icon(
                            Icons.arrow_drop_up,
                            size: 28,
                            color: indicatorColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Center dot ──
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: indicatorColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              // ── "القبلة" label pinned below the Kaaba (also rotates) ──
              AnimatedRotation(
                turns: angle / (2 * pi),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'القبلة',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // ── "You" indicator at bottom (your current facing direction) ──
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'أنت',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Degree readout
        Text(
          '${degrees.toStringAsFixed(1)}°',
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
