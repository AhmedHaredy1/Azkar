import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/app_colors.dart';
import 'providers/sebha_provider.dart';
import 'widgets/sebha_circle.dart';

class SebhaScreen extends ConsumerWidget {
  const SebhaScreen({super.key});

  static const _dhikrOptions = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'سبحان الله وبحمده',
    'لا حول ولا قوة إلا بالله',
  ];

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sebhaState = ref.watch(sebhaProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'السبحة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(sebhaProvider.notifier).resetCurrent();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة تعيين',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Dhikr selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _dhikrOptions.contains(sebhaState.selectedDhikr)
                      ? sebhaState.selectedDhikr
                      : _dhikrOptions.first,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                  items: _dhikrOptions.map((dhikr) {
                    return DropdownMenuItem(
                      value: dhikr,
                      child: Text(
                        dhikr,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(sebhaProvider.notifier).selectDhikr(value);
                    }
                  },
                ),
              ),
            ),
            const Spacer(),
            // Main counter circle
            SebhaCircle(
              currentCount: sebhaState.currentCount,
              targetCount: sebhaState.targetCount,
              onTap: () async {
                ref.read(sebhaProvider.notifier).increment();
                if (await Vibration.hasVibrator()) {
                  Vibration.vibrate(duration: 20);
                }
              },
            ),
            const SizedBox(height: 24),
            // Selected dhikr text
            Text(
              sebhaState.selectedDhikr,
              style: GoogleFonts.amiri(
                fontSize: 24,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Total count
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.all_inclusive,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'الإجمالي: ${_toArabicNumber(sebhaState.totalCount)}',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Target selector row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [33, 100, 500, 1000].map((target) {
                  final isSelected = sebhaState.targetCount == target;
                  return GestureDetector(
                    onTap: () => ref.read(sebhaProvider.notifier).setTarget(target),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        _toArabicNumber(target),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
