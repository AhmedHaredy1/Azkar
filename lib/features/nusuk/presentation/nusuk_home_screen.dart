import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../domain/nusuk_flows.dart';
import '../domain/nusuk_type.dart';
import 'providers/nusuk_provider.dart';
import 'widgets/nusuk_type_card.dart';

/// Hub for the interactive ritual tracker («ابدأ نسكي»): resume an in-progress
/// rite, pick a Nusuk to start, or open the history. Lives inside the shell.
class NusukHomeScreen extends ConsumerWidget {
  const NusukHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(nusukSessionProvider);
    final history = ref.watch(nusukHistoryProvider);
    final hijriYear = currentHijriYear();

    // A Hajj is "taken" for the year if completed in history or in progress now.
    final hajjThisYear =
        history.any((r) => r.type.isHajj && r.hijriYear == hijriYear) ||
            (active != null && active.type.isHajj && active.hijriYear == hijriYear);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'نُسُكي',
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _IntroBanner(),
          const SizedBox(height: AppSpacing.lg),
          if (active != null) ...[
            _ResumeCard(
              typeName: active.type.arabicName,
              completed: active.completedStepIds.length,
              total: stepCountForType(active.type),
              onTap: () => context.push('/nusuk-session'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _SectionLabel(
            icon: Icons.touch_app_outlined,
            label: active == null ? 'اختر النُّسُك للبدء' : 'أو ابدأ نُسُكاً جديداً',
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final type in NusukType.values) ...[
            NusukTypeCard(
              type: type,
              disabled: type.isHajj && hajjThisYear,
              disabledNote: 'لا يمكن أداء أكثر من حجّة في العام الهجري الواحد',
              onTap: () => _onSelectType(context, ref, type),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.push('/nusuk-history'),
            icon: const Icon(Icons.history_rounded, size: 20),
            label: Text(
              history.isEmpty
                  ? 'سجلّ مناسكي'
                  : 'سجلّ مناسكي (${ArabicNumberUtils.toEasternArabic(history.length)})',
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelectType(
    BuildContext context,
    WidgetRef ref,
    NusukType type,
  ) async {
    final notifier = ref.read(nusukSessionProvider.notifier);
    final active = ref.read(nusukSessionProvider);

    // Replacing an in-progress rite needs explicit confirmation.
    if (active != null) {
      final confirmed = await _confirm(
        context,
        title: 'نُسُك قيد التنفيذ',
        message:
            'لديك «${active.type.arabicName}» قيد التنفيذ. بدء نُسُك جديد سيُلغي '
            'تقدّمك الحالي. هل تريد المتابعة؟',
        confirmLabel: 'إلغاء وبدء جديد',
      );
      if (confirmed != true) return;
      notifier.cancelSession();
    }

    final result = notifier.startSession(type);
    if (result == StartResult.blockedHajj) {
      if (context.mounted) _showHajjBlocked(context);
      return;
    }
    if (context.mounted) context.push('/nusuk-session');
  }

  void _showHajjBlocked(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'لا يمكن بدء حجّة جديدة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'لقد سجّلت حجّة في هذا العام الهجري. يُمكن أداء حجّة واحدة فقط في '
          'العام. لبدء حجّة جديدة احذف السجل السابق من «سجلّ مناسكي».',
          style: GoogleFonts.cairo(height: 1.7, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('حسناً', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/nusuk-history');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('عرض السجل', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
          message,
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
            child: Text(confirmLabel, style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mosque_rounded,
              color: Colors.white.withValues(alpha: 0.95), size: 34),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'رفيقك في المناسك',
            style: GoogleFonts.cairo(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اتبع مناسك حجك أو عمرتك خطوةً بخطوة، مع التتبّع والعدّادات والأدعية، '
            'وسجِّل ما أتممته في سِجلّك الخاص.',
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.7,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final String typeName;
  final int completed;
  final int total;
  final VoidCallback onTap;

  const _ResumeCard({
    required this.typeName,
    required this.completed,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final fraction = total == 0 ? 0.0 : completed / total;
    final percent = (fraction * 100).round();

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: primary.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: primary, size: 26),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'تابع نُسُكك — $typeName',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${ArabicNumberUtils.toEasternArabic(percent)}٪',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceSunk,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'أكملت ${ArabicNumberUtils.toEasternArabic(completed)} '
                'من ${ArabicNumberUtils.toEasternArabic(total)} خطوات',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
