import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../domain/nusuk_flows.dart';
import '../domain/nusuk_record.dart';
import '../domain/nusuk_session.dart';
import '../domain/nusuk_step.dart';
import '../domain/nusuk_type.dart';
import 'providers/nusuk_provider.dart';
import 'widgets/nusuk_progress_header.dart';
import 'widgets/nusuk_step_view.dart';

/// The immersive, full-screen guided session (outside the shell — no bottom
/// nav). Renders the ordered steps with the active one expanded and future
/// ones locked; the session notifier enforces that steps can't be skipped.
class NusukSessionScreen extends ConsumerWidget {
  const NusukSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(nusukSessionProvider);

    if (session == null) {
      return const _EmptyFallback();
    }

    final steps = stepsForType(session.type);
    final current = session.currentStepIndex;
    final notifier = ref.read(nusukSessionProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          session.type.arabicName,
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'restart') _confirmRestart(context, ref);
              if (value == 'cancel') _confirmCancel(context, ref);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'restart',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded,
                        size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('إعادة من البداية', style: GoogleFonts.cairo()),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.close_rounded, size: 20, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Text('إلغاء النُّسُك',
                        style: GoogleFonts.cairo(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          NusukProgressHeader(
            type: session.type,
            completedCount: session.completedStepIds.length,
            totalCount: session.requiredCount(steps.length),
            currentStepTitle: current < steps.length ? steps[current].title : '',
          ),
          if (session.mode == NusukMode.practice) ...[
            const SizedBox(height: AppSpacing.md),
            const _PracticeBanner(),
          ],
          const SizedBox(height: AppSpacing.lg),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _stepTile(context, notifier, steps, i, session),
            ),
        ],
      ),
    );
  }

  Widget _stepTile(
    BuildContext context,
    NusukSessionNotifier notifier,
    List<NusukStep> steps,
    int index,
    NusukSession session,
  ) {
    final step = steps[index];
    final number = index + 1;

    if (session.isStepSkipped(step.id)) {
      return _SkippedTile(number: number, title: step.title);
    }

    if (session.isStepCompleted(step.id)) {
      return _CompletedTile(
        number: number,
        title: step.title,
        detail: _completedDetail(step, session),
      );
    }

    if (index == session.currentStepIndex) {
      return _ActiveStepCard(
        number: number,
        step: step,
        session: session,
        gate: nusukDateGate(session, step),
        onStart: () => notifier.startStep(step.id),
        onComplete: () =>
            _handle(context, notifier.completeStep(step.id), session.mode),
        onIncrement: () =>
            _handle(context, notifier.incrementCounter(step.id), session.mode),
        onSelectChoice: (id) => notifier.selectChoice(step.id, id),
      );
    }

    return _LockedTile(number: number, title: step.title);
  }

  /// If an action finalized the rite, jump to the completion screen. Practice
  /// runs pass `practice=1` so the celebration omits the (empty) record log.
  void _handle(BuildContext context, NusukRecord? finished, NusukMode mode) {
    if (finished != null) {
      final practice = mode == NusukMode.practice ? '&practice=1' : '';
      context.pushReplacement(
        '/nusuk-complete?record=${finished.recordId}$practice',
        extra: finished,
      );
    }
  }

  String? _completedDetail(NusukStep step, NusukSession session) {
    if (step.kind == NusukStepKind.choice) {
      final id = session.choiceOf(step.id);
      for (final c in step.choices) {
        if (c.id == id) return c.label;
      }
    }
    if (step.kind == NusukStepKind.counter) {
      final target = step.counterTarget ?? 0;
      return '${ArabicNumberUtils.toEasternArabic(target)} ${step.counterUnit}';
    }
    return null;
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'إلغاء النُّسُك',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'سيتم حذف تقدّمك في هذا النُّسُك. يمكنك المغادرة بزر الرجوع للاحتفاظ '
          'به والعودة لاحقاً. هل تريد الإلغاء نهائياً؟',
          style: GoogleFonts.cairo(height: 1.7, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('تراجع', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('إلغاء النُّسُك', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(nusukSessionProvider.notifier).cancelSession();
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/nusuk');
    }
  }

  Future<void> _confirmRestart(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'إعادة النُّسُك',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'سيعود تقدّمك إلى الخطوة الأولى مع الاحتفاظ بنفس النُّسُك. '
          'هل تريد المتابعة؟',
          style: GoogleFonts.cairo(height: 1.7, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('تراجع', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('إعادة', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(nusukSessionProvider.notifier).restart();
    }
  }
}

class _ActiveStepCard extends StatelessWidget {
  final int number;
  final NusukStep step;
  final NusukSession session;
  final NusukStepGate gate;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onIncrement;
  final ValueChanged<String> onSelectChoice;

  const _ActiveStepCard({
    required this.number,
    required this.step,
    required this.session,
    required this.gate,
    required this.onStart,
    required this.onComplete,
    required this.onIncrement,
    required this.onSelectChoice,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: primary.withValues(alpha: 0.45), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberBadge(number: number, color: primary, filled: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  step.title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          NusukStepView(
            step: step,
            session: session,
            gate: gate,
            onStart: onStart,
            onComplete: onComplete,
            onIncrement: onIncrement,
            onSelectChoice: onSelectChoice,
          ),
        ],
      ),
    );
  }
}

class _CompletedTile extends StatelessWidget {
  final int number;
  final String title;
  final String? detail;

  const _CompletedTile({
    required this.number,
    required this.title,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
        ],
      ),
    );
  }
}

/// A step dropped by التعجّل (early departure) — shown greyed with a skip mark.
class _SkippedTile extends StatelessWidget {
  final int number;
  final String title;

  const _SkippedTile({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunk,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.skip_next_rounded, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textTertiary,
              ),
            ),
          ),
          Text(
            'تُجووِزت — التعجّل',
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header strip clarifying that date locks are off in practice mode.
class _PracticeBanner extends StatelessWidget {
  const _PracticeBanner();

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.secondaryDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'وضع التدريب والاستعراض — قيود التواريخ غير مُفعّلة، يمكنك تجربة '
              'جميع الخطوات.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedTile extends StatelessWidget {
  final int number;
  final String title;

  const _LockedTile({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _NumberBadge(number: number, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  final Color color;
  final bool filled;

  const _NumberBadge({
    required this.number,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        ArabicNumberUtils.toEasternArabic(number),
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: filled ? AppColors.textOnPrimary : color,
        ),
      ),
    );
  }
}

class _EmptyFallback extends StatelessWidget {
  const _EmptyFallback();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا يوجد نُسُك نشِط حالياً',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.go('/nusuk'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text('العودة إلى نُسُكي', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
