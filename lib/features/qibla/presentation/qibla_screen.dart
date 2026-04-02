import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'providers/qibla_provider.dart';
import 'widgets/qibla_compass.dart';

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qiblaAngle = ref.watch(qiblaCompassAngleProvider);

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
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Kaaba icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.mosque,
                      size: 36,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'وجّه هاتفك نحو القبلة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  QiblaCompass(angle: angle),
                  const SizedBox(height: 40),
                  // Info text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'ضع هاتفك على سطح مستوٍ للحصول على أدق قراءة',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'جاري تحديد الاتجاه...',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.explore_off, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'تعذّر تحديد اتجاه القبلة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تأكد من تفعيل خدمة الموقع والبوصلة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
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
            ),
          ),
        ),
      ),
    );
  }
}
