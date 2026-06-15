import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/nusuk_session.dart';
import '../../domain/nusuk_step.dart';
import 'nusuk_counter_tracker.dart';

/// Renders the body + action area of the *active* step. Purely presentational:
/// all mutations are delegated to the parent via callbacks (the screen wires
/// them to the session notifier and handles completion navigation).
class NusukStepView extends StatelessWidget {
  final NusukStep step;
  final NusukSession session;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onIncrement;
  final ValueChanged<String> onSelectChoice;

  const NusukStepView({
    super.key,
    required this.step,
    required this.session,
    required this.onStart,
    required this.onComplete,
    required this.onIncrement,
    required this.onSelectChoice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (step.dayLabel != null) ...[
          _DayChip(label: step.dayLabel!),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (step.description.isNotEmpty)
          Text(
            step.description,
            style: GoogleFonts.cairo(
              fontSize: 14.5,
              height: 1.85,
              color: AppColors.textPrimary,
            ),
          ),
        if (step.talbiyah != null) ...[
          const SizedBox(height: AppSpacing.md),
          _Callout(
            title: 'التلبية',
            icon: Icons.campaign_outlined,
            body: step.talbiyah!,
            amiri: true,
          ),
        ],
        if (step.duas.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _DuasCallout(duas: step.duas),
        ],
        if (step.guidance != null) ...[
          const SizedBox(height: AppSpacing.md),
          _Callout(
            title: 'إرشاد',
            icon: Icons.lightbulb_outline_rounded,
            body: step.guidance!,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _action(context),
      ],
    );
  }

  Widget _action(BuildContext context) {
    switch (step.kind) {
      case NusukStepKind.counter:
        return NusukCounterTracker(
          current: session.counterOf(step.id),
          target: step.counterTarget ?? 0,
          unit: step.counterUnit,
          onIncrement: onIncrement,
        );
      case NusukStepKind.choice:
        return _ChoiceArea(
          step: step,
          selectedId: session.choiceOf(step.id),
          onSelect: onSelectChoice,
          onComplete: onComplete,
        );
      case NusukStepKind.info:
        final started = session.isStepStarted(step.id);
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: started ? onComplete : onStart,
            icon: Icon(
              started ? Icons.check_circle_outline_rounded : Icons.play_arrow_rounded,
              size: 20,
            ),
            label: Text(
              started ? 'أكملت الخطوة' : 'ابدأ الخطوة',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor:
                  started ? AppColors.success : AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        );
    }
  }
}

class _ChoiceArea extends StatelessWidget {
  final NusukStep step;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onComplete;

  const _ChoiceArea({
    required this.step,
    required this.selectedId,
    required this.onSelect,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final choice in step.choices) ...[
              Expanded(
                child: _ChoiceTile(
                  label: choice.label,
                  note: choice.note,
                  selected: selectedId == choice.id,
                  onTap: () => onSelect(choice.id),
                ),
              ),
              if (choice != step.choices.last)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: selectedId == null ? null : onComplete,
          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: Text(
            'إتمام الخطوة',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: AppColors.textOnPrimary,
            disabledBackgroundColor: AppColors.surfaceSunk,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final String? note;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? primary : AppColors.hairlineStrong,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? primary : AppColors.textTertiary,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: selected ? primary : AppColors.textPrimary,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(
                note!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  const _DayChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_outlined, size: 14, color: secondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final String title;
  final IconData icon;
  final String body;
  final bool amiri;

  const _Callout({
    required this.title,
    required this.icon,
    required this.body,
    this.amiri = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: amiri
                ? GoogleFonts.amiri(
                    fontSize: 17,
                    height: 1.9,
                    color: AppColors.textPrimary,
                  )
                : GoogleFonts.cairo(
                    fontSize: 13.5,
                    height: 1.7,
                    color: AppColors.textPrimary,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DuasCallout extends StatelessWidget {
  final List<String> duas;
  const _DuasCallout({required this.duas});

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                'الأدعية المأثورة',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...duas.map(
            (dua) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '• $dua',
                style: GoogleFonts.amiri(
                  fontSize: 16,
                  height: 1.9,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
