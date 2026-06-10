import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const _shortDhikrOptions = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'أستغفر الله',
    'لا حول ولا قوة إلا بالله',
    'اللهم صلِّ على محمد',
  ];

  static const _fullDhikrOptions = [
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
  ];

  bool _celebrationShown = false;
  bool _vibrate = true;
  bool? _hasVibrator;

  @override
  void initState() {
    super.initState();
    // Probe the vibrator once — calling Vibration.hasVibrator() on every tap
    // delays the haptic noticeably and on Android 13+ sometimes returns false
    // even on devices that vibrate fine.
    Vibration.hasVibrator().then((has) {
      if (mounted) setState(() => _hasVibrator = has);
    });
  }

  Future<void> _vibrateOnTap() async {
    if (!_vibrate) return;
    // HapticFeedback uses the platform's native haptic API directly — works
    // on virtually every device regardless of what hasVibrator reports.
    HapticFeedback.selectionClick();
    if (_hasVibrator == true) {
      Vibration.vibrate(duration: 40);
    }
  }

  void _showDhikrPicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                const SizedBox(height: AppSpacing.sm + 2),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairlineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'اختر الذكر',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _fullDhikrOptions.length,
                    separatorBuilder: (_, _) => Container(
                      height: 1,
                      color: AppColors.hairline,
                    ),
                    itemBuilder: (context, index) {
                      final dhikr = _fullDhikrOptions[index];
                      final isSelected = dhikr == current;
                      return InkWell(
                        onTap: () {
                          ref.read(sebhaProvider.notifier).selectDhikr(dhikr);
                          _celebrationShown = false;
                          Navigator.of(ctx).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 18,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.ink3,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  dhikr,
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.notoNaskhArabic(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.ink
                                        : AppColors.ink2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  void _showTargetCompletionDialog(BuildContext context, int target) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'ما شاء الله',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'أتممت ${ArabicNumberUtils.toEasternArabic(target)} تسبيحة',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.ink3,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.hairline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    foregroundColor: AppColors.ink2,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'متابعة',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    ref.read(sebhaProvider.notifier).resetCurrent();
                    _celebrationShown = false;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'البدء من جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sebhaState = ref.watch(sebhaProvider);

    if (sebhaState.currentCount > 0 &&
        sebhaState.currentCount >= sebhaState.targetCount &&
        !_celebrationShown) {
      _celebrationShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTargetCompletionDialog(context, sebhaState.targetCount);
      });
    }

    final selectedDhikr = sebhaState.selectedDhikr.isNotEmpty
        ? sebhaState.selectedDhikr
        : _shortDhikrOptions.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'المسبحة',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                _showDhikrPicker(context, ref, sebhaState.selectedDhikr),
            icon: const Icon(Icons.tune_rounded, size: 20),
            color: AppColors.ink2,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'الذِّكر الحالي',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.ink3,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                selectedDhikr,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoNaskhArabic(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${ArabicNumberUtils.toEasternArabic(sebhaState.targetCount)} مرة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SebhaCircle(
                currentCount: sebhaState.currentCount,
                targetCount: sebhaState.targetCount,
                onTap: () {
                  ref.read(sebhaProvider.notifier).increment();
                  _vibrateOnTap();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              _DhikrChipRow(
                options: _shortDhikrOptions,
                selected: selectedDhikr,
                onSelect: (d) {
                  ref.read(sebhaProvider.notifier).selectDhikr(d);
                  _celebrationShown = false;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _TargetChipRow(
                selected: sebhaState.targetCount,
                onSelect: (t) {
                  ref.read(sebhaProvider.notifier).setTarget(t);
                  _celebrationShown = false;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      icon: _vibrate
                          ? Icons.vibration
                          : Icons.do_not_disturb_on_outlined,
                      label: _vibrate ? 'اهتزاز' : 'صامت',
                      onTap: () => setState(() => _vibrate = !_vibrate),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.restart_alt_rounded,
                      label: 'إعادة تعيين',
                      onTap: () {
                        ref.read(sebhaProvider.notifier).resetCurrent();
                        _celebrationShown = false;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  'الإجمالي: ${ArabicNumberUtils.toEasternArabic(sebhaState.totalCount)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _DhikrChipRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _DhikrChipRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final d in options) ...[
            GestureDetector(
              onTap: () => onSelect(d),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: d == selected ? AppColors.ink : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: d == selected ? AppColors.ink : AppColors.hairline,
                  ),
                ),
                child: Text(
                  d,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: d == selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: d == selected ? Colors.white : AppColors.ink2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TargetChipRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _TargetChipRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const targets = [33, 99, 100, 1000];
    return Row(
      children: [
        for (int i = 0; i < targets.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(targets[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: selected == targets[i]
                      ? AppColors.primarySoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: selected == targets[i]
                        ? AppColors.primary
                        : AppColors.hairline,
                  ),
                ),
                child: Text(
                  ArabicNumberUtils.toEasternArabic(targets[i]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected == targets[i]
                        ? AppColors.primary
                        : AppColors.ink2,
                  ),
                ),
              ),
            ),
          ),
          if (i != targets.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.ink2),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.ink2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
