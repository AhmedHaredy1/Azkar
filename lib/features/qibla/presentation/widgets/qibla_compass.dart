import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class QiblaCompass extends StatelessWidget {
  /// The angle in radians to rotate the compass so the needle points to Qibla
  final double angle;

  const QiblaCompass({super.key, required this.angle});

  @override
  Widget build(BuildContext context) {
    final degrees = (angle * 180 / pi) % 360;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Degree display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${degrees.toStringAsFixed(1)}°',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Compass
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Compass face
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: 260,
                  height: 260,
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
                      // Cardinal directions
                      Positioned(
                        top: 16,
                        child: Text(
                          'ش',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        child: Text(
                          'ج',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        child: Text(
                          'شر',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        child: Text(
                          'غر',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      // Tick marks
                      ...List.generate(36, (i) {
                        final tickAngle = i * 10 * pi / 180;
                        final isMain = i % 9 == 0;
                        return Transform.rotate(
                          angle: tickAngle,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: isMain ? 2 : 1,
                              height: isMain ? 14 : 8,
                              color: isMain
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withValues(alpha: 0.3),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Qibla needle (stays pointing up = toward Qibla when rotated)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.navigation,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'القبلة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
