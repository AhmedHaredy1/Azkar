import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/arabic_number_utils.dart';
import 'providers/sebha_provider.dart';
import 'widgets/sebha_circle.dart';

class SebhaScreen extends ConsumerStatefulWidget {
  const SebhaScreen({super.key});

  @override
  ConsumerState<SebhaScreen> createState() => _SebhaScreenState();
}

class _SebhaScreenState extends ConsumerState<SebhaScreen> {
  static const _dhikrOptions = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'سبحان الله وبحمده',
    'لا حول ولا قوة إلا بالله',
  ];

  bool _celebrationShown = false;

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'إعادة تعيين العداد',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'هل تريد إعادة تعيين العداد؟',
          style: GoogleFonts.cairo(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(sebhaProvider.notifier).resetCurrent();
              _celebrationShown = false;
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إعادة تعيين',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showTargetCompletionDialog(BuildContext context, int target) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ما شاء الله!',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أتممت ${ArabicNumberUtils.toEasternArabic(target)} تسبيحة',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'تقبّل الله منك',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(
              'متابعة',
              style: GoogleFonts.cairo(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(sebhaProvider.notifier).resetCurrent();
              _celebrationShown = false;
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'البدء من جديد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sebhaState = ref.watch(sebhaProvider);

    // Check if target reached and show celebration
    if (sebhaState.currentCount > 0 &&
        sebhaState.currentCount >= sebhaState.targetCount &&
        !_celebrationShown) {
      _celebrationShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTargetCompletionDialog(context, sebhaState.targetCount);
      });
    }

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
            onPressed: () => _showResetConfirmation(context, ref),
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
                      _celebrationShown = false;
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
                    'الإجمالي: ${ArabicNumberUtils.toEasternArabic(sebhaState.totalCount)}',
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
                children: [33, 99, 100, 1000].map((target) {
                  final isSelected = sebhaState.targetCount == target;
                  return GestureDetector(
                    onTap: () {
                      ref.read(sebhaProvider.notifier).setTarget(target);
                      _celebrationShown = false;
                    },
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
                        ArabicNumberUtils.toEasternArabic(target),
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
