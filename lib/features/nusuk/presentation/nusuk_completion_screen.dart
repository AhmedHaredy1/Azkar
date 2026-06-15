import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../domain/nusuk_flows.dart';
import '../domain/nusuk_record.dart';
import '../domain/nusuk_type.dart';
import 'providers/nusuk_provider.dart';

/// Celebration shown when a rite is finished (full-screen, outside the shell).
/// The record arrives via GoRouter `extra` (immediate) and falls back to a
/// history lookup by [recordId] on a cold reload.
class NusukCompletionScreen extends ConsumerWidget {
  final NusukRecord? record;
  final String? recordId;

  const NusukCompletionScreen({super.key, this.record, this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(nusukHistoryProvider);
    final resolved = record ?? _lookup(history);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              _Medallion(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'تقبّل اللهُ طاعتك',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                resolved == null
                    ? 'أتممت نُسُكك بحمد الله'
                    : 'أتممت ${resolved.type.arabicName} بحمد الله',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (resolved != null) _SummaryCard(record: resolved),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => context.go('/nusuk-history'),
                icon: const Icon(Icons.history_rounded, size: 20),
                label: Text(
                  'عرض السجل',
                  style:
                      GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'العودة إلى الرئيسية',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  NusukRecord? _lookup(List<NusukRecord> history) {
    if (recordId == null) return null;
    for (final r in history) {
      if (r.recordId == recordId) return r;
    }
    return null;
  }
}

class _Medallion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    return Center(
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary.withValues(alpha: 0.10),
          border: Border.all(color: primary.withValues(alpha: 0.30), width: 2),
        ),
        child: Icon(Icons.verified_rounded, size: 56, color: primary),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final NusukRecord record;

  const _SummaryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final steps = stepCountForType(record.type);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _Row(
            icon: Icons.menu_book_rounded,
            label: 'النُّسُك',
            value: record.type.arabicName,
          ),
          const _Divider(),
          _Row(
            icon: Icons.checklist_rounded,
            label: 'عدد الخطوات',
            value: '${ArabicNumberUtils.toEasternArabic(steps)} خطوات',
          ),
          const _Divider(),
          _Row(
            icon: Icons.brightness_2_outlined,
            label: 'التاريخ الهجري',
            value: record.hijriDateStr,
          ),
          const _Divider(),
          _Row(
            icon: Icons.calendar_today_outlined,
            label: 'التاريخ الميلادي',
            value: formatGregorianDate(record.completedAt),
          ),
          const _Divider(),
          _Row(
            icon: Icons.access_time_rounded,
            label: 'وقت الإتمام',
            value: formatClockTime(record.completedAt),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: AppColors.hairline);
  }
}
