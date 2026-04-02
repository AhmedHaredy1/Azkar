import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import 'providers/settings_provider.dart';
import 'widgets/font_size_slider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _calculationMethods = <String, String>{
    'UmmAlQura': 'أم القرى',
    'Egyptian': 'الهيئة المصرية',
    'MuslimWorldLeague': 'رابطة العالم الإسلامي',
    'Karachi': 'جامعة العلوم الإسلامية - كراتشي',
    'NorthAmerica': 'أمريكا الشمالية',
    'Dubai': 'دبي',
    'Kuwait': 'الكويت',
    'Qatar': 'قطر',
    'Singapore': 'سنغافورة',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font Size Section
            _SectionHeader(title: 'حجم الخط'),
            const SizedBox(height: 12),
            FontSizeSlider(
              value: settings.fontSize,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setFontSize(value);
              },
            ),
            const SizedBox(height: 28),

            // Calculation Method Section
            _SectionHeader(title: 'طريقة حساب مواقيت الصلاة'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _calculationMethods.containsKey(settings.calculationMethod)
                      ? settings.calculationMethod
                      : 'UmmAlQura',
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  items: _calculationMethods.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setCalculationMethod(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),

            // About Section
            _SectionHeader(title: 'عن التطبيق'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.mosque_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'حصن المسلم',
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الإصدار 1.0.0',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تطبيق الأذكار والأدعية من الكتاب والسنة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share App
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Share.share('حمّل تطبيق حصن المسلم - أذكار وأدعية من الكتاب والسنة');
                },
                icon: const Icon(Icons.share_outlined),
                label: Text(
                  'مشاركة التطبيق',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
