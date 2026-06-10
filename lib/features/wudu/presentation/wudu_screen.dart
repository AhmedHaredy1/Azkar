import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';

class WuduStep {
  final int step;
  final String title;
  final String description;
  final String icon;
  final String tip;
  const WuduStep({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    required this.tip,
  });
  factory WuduStep.fromJson(Map<String, dynamic> j) => WuduStep(
        step: j['step'] as int,
        title: j['title'] as String,
        description: j['description'] as String,
        icon: j['icon'] as String,
        tip: j['tip'] as String,
      );
}

final wuduStepsProvider = FutureProvider<List<WuduStep>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/wudu.json');
  final List list = json.decode(raw) as List;
  return list
      .map((e) => WuduStep.fromJson(e as Map<String, dynamic>))
      .toList();
});

class WuduScreen extends ConsumerStatefulWidget {
  const WuduScreen({super.key});

  @override
  ConsumerState<WuduScreen> createState() => _WuduScreenState();
}

class _WuduScreenState extends ConsumerState<WuduScreen> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wuduStepsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'الوضوء',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      body: async.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'خطأ: $e',
            style: GoogleFonts.cairo(color: AppColors.ink2),
          ),
        ),
        data: (steps) {
          if (steps.isEmpty) return const SizedBox.shrink();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Intro(total: steps.length),
                const SizedBox(height: AppSpacing.lg),
                _StepRail(
                  steps: steps,
                  activeIndex: _activeIndex,
                  onTap: (i) => setState(() => _activeIndex = i),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final int total;
  const _Intro({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الوضوء الشرعي',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ArabicNumberUtils.toEasternArabic(total)} خطوات مع توضيحات',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRail extends StatelessWidget {
  final List<WuduStep> steps;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _StepRail({
    required this.steps,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.directional(
          textDirection: TextDirection.rtl,
          start: 19,
          top: 24,
          bottom: 24,
          child: Container(width: 1.5, color: AppColors.hairline),
        ),
        Column(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _StepRow(
                step: steps[i],
                isActive: i == activeIndex,
                isDone: i < activeIndex,
                onTap: () => onTap(i),
              ),
              if (i != steps.length - 1) const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final WuduStep step;
  final bool isActive;
  final bool isDone;
  final VoidCallback onTap;

  const _StepRow({
    required this.step,
    required this.isActive,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepMarker(step: step, isActive: isActive, isDone: isDone),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.hairline,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.description,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.ink3,
                      height: 1.5,
                    ),
                  ),
                  if (isActive && step.tip.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm + 2),
                    Container(
                      height: 1,
                      color: AppColors.hairline,
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 14, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            step.tip,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: AppColors.ink2,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepMarker extends StatelessWidget {
  final WuduStep step;
  final bool isActive;
  final bool isDone;

  const _StepMarker({
    required this.step,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    if (isActive) {
      bg = AppColors.primary;
      border = AppColors.primary;
    } else if (isDone) {
      bg = AppColors.primarySoft;
      border = AppColors.primarySoft;
    } else {
      bg = AppColors.surface;
      border = AppColors.hairlineStrong;
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      alignment: Alignment.center,
      child: isDone
          ? Icon(Icons.check, size: 16, color: AppColors.primary)
          : Text(
              ArabicNumberUtils.toEasternArabic(step.step),
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.ink3,
              ),
            ),
    );
  }
}
