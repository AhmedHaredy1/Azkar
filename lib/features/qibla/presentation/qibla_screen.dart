import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import 'providers/qibla_provider.dart';
import 'widgets/qibla_compass.dart';

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qiblaAngle = ref.watch(qiblaCompassAngleProvider);
    final compassAccuracy = ref.watch(compassAccuracyProvider);

    // Check if calibration needed (accuracy < 15 degrees = low)
    final bool needsCalibration = compassAccuracy.when(
      data: (accuracy) => accuracy != null && accuracy < 15,
      loading: () => false,
      error: (_, _) => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اتجاه القبلة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: qiblaAngle.when(
            data: (angle) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    // Calibration warning
                    if (needsCalibration)
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.sm,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.secondary,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'قم بتحريك الهاتف على شكل رقم ٨ لمعايرة البوصلة',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    // Kaaba image
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.asset(
                          'assets/images/kaaba.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'وجّه هاتفك نحو القبلة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    QiblaCompass(angle: angle),
                    const SizedBox(height: AppSpacing.xxl),
                    // Info text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Text(
                        'ضع هاتفك على سطح مستوٍ للحصول على أدق قراءة',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
            loading: () => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'جاري تحديد الاتجاه...',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            error: (error, _) {
              // Check if this is likely a missing compass sensor
              final errorMsg = error.toString().toLowerCase();
              final isCompassMissing = errorMsg.contains('timeout') ||
                  errorMsg.contains('sensor') ||
                  errorMsg.contains('compass') ||
                  errorMsg.contains('empty');

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCompassMissing ? Icons.sensors_off : Icons.explore_off,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      isCompassMissing
                          ? 'جهازك لا يدعم البوصلة'
                          : 'تعذّر تحديد اتجاه القبلة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isCompassMissing
                          ? 'هذا الجهاز لا يحتوي على مستشعر بوصلة (مقياس مغناطيسي)'
                          : 'تأكد من تفعيل خدمة الموقع والبوصلة',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (!isCompassMissing)
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(qiblaDirectionProvider);
                          ref.invalidate(compassHeadingProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
