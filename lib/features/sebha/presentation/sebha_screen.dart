import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
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
    'سبحان الله وبحمده سبحان الله العظيم',
    'سبحان الله والحمد لله ولا إله إلا الله والله أكبر',
    'لا حول ولا قوة إلا بالله',
    'أستغفر الله',
    'أستغفر الله العظيم وأتوب إليه',
    'اللهم صلِّ وسلم على نبينا محمد',
    'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير',
    'سبحان الله وبحمده عدد خلقه ورضا نفسه وزنة عرشه ومداد كلماته',
    'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم',
    'اللهم إني أسألك العفو والعافية',
    'يا حي يا قيوم برحمتك أستغيث',
    'لا إله إلا أنت سبحانك إني كنت من الظالمين',
    'رب اغفر لي وتب عليّ إنك أنت التواب الرحيم',
    'اللهم أجرني من النار',
    'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار',
    'حسبنا الله ونعم الوكيل',
    'اللهم اغفر للمسلمين والمسلمات',
    'رب اشرح لي صدري ويسر لي أمري',
    'اللهم إنك عفو تحب العفو فاعف عني',
    'لا إله إلا الله العظيم الحليم، لا إله إلا الله رب العرش العظيم',
  ];

  bool _celebrationShown = false;

  void _showDhikrPicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.sheetTop,
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر الذكر',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _dhikrOptions.length,
                    itemBuilder: (context, index) {
                      final dhikr = _dhikrOptions[index];
                      final isSelected = dhikr == current;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          dhikr,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiri(
                            fontSize: 17,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        onTap: () {
                          ref.read(sebhaProvider.notifier).selectDhikr(dhikr);
                          _celebrationShown = false;
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
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
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.button,
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
        ),
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
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.button,
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
            const SizedBox(height: AppSpacing.xl),
            // Dhikr selector (tap to open picker)
            GestureDetector(
              onTap: () => _showDhikrPicker(context, ref, sebhaState.selectedDhikr),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dhikrOptions.contains(sebhaState.selectedDhikr)
                            ? sebhaState.selectedDhikr
                            : _dhikrOptions.first,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  ],
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
            const SizedBox(height: AppSpacing.xl),
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
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
                horizontal: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: AppRadius.card,
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
            const SizedBox(height: AppSpacing.lg),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.card,
                        borderRadius: AppRadius.button,
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
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
