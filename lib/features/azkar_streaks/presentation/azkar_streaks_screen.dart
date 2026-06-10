import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../../core/widgets/ornaments.dart';
import 'providers/azkar_streaks_provider.dart';

class AzkarStreaksScreen extends ConsumerWidget {
  const AzkarStreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(azkarStreaksProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'حسابي',
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined,
                size: 20, color: AppColors.ink2),
            tooltip: 'مسح السجل',
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          _StreakHero(state: state),
          const SizedBox(height: AppSpacing.lg + 4),
          _SectionLabel(label: 'إحصاءات الأسبوع'),
          const SizedBox(height: AppSpacing.sm + 2),
          _StatsCard(state: state),
          const SizedBox(height: AppSpacing.lg + 4),
          _SectionLabel(label: 'إنجازات'),
          const SizedBox(height: AppSpacing.sm + 2),
          _AchievementsGrid(state: state),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(label: 'خريطة الاستمرار'),
          const SizedBox(height: AppSpacing.sm + 2),
          _HeatmapCard(state: state),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'مسح السجل',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'سيتم حذف كامل سجل الأذكار. هل أنت متأكد؟',
          style: GoogleFonts.cairo(color: AppColors.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: AppColors.ink3),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(azkarStreaksProvider.notifier).reset();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.ink3,
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  final AzkarStreaksState state;
  const _StreakHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final streak = state.currentStreak;
    // Build the last 7 days status (oldest → today).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStatus = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return state.didMorning(day) || state.didEvening(day);
    });
    const weekdayLabels = ['ح', 'إ', 'ث', 'ر', 'خ', 'ج', 'س']; // start Sunday
    // Derive labels aligned to the actual weekdays we show.
    final labels = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      // DateTime.weekday: Mon=1..Sun=7 → map to index 0..6 (Sun=0, Sat=6)
      final idx = day.weekday % 7;
      return weekdayLabels[idx];
    });

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: GeoWatermark(
                size: 280,
                color: AppColors.secondaryLight,
                opacity: 0.08,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سلسلة مستمرة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      ArabicNumberUtils.toEasternArabic(streak),
                      style: GoogleFonts.cairo(
                        fontSize: 56,
                        fontWeight: FontWeight.w300,
                        height: 1,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'يوماً',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  streak == 0 ? 'ابدأ سلسلتك اليوم' : 'هذا الأسبوع',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    for (int i = 0; i < 7; i++) ...[
                      Expanded(
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: weekStatus[i]
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: weekStatus[i]
                                      ? null
                                      : Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                          style: BorderStyle.solid,
                                          width: 1,
                                        ),
                                ),
                                child: weekStatus[i]
                                    ? const Center(
                                        child: StarMark(
                                          size: 10,
                                          color: AppColors.ink,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              labels[i],
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < 6) const SizedBox(width: 6),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final AzkarStreaksState state;
  const _StatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = <_StatDef>[
      _StatDef(
        label: 'أطول سلسلة',
        tag: 'يوم',
        value: state.longestStreak,
      ),
      _StatDef(
        label: 'أيام الصباح',
        tag: 'جلسة',
        value: state.morningCount,
      ),
      _StatDef(
        label: 'أيام المساء',
        tag: 'جلسة',
        value: state.eveningCount,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              _StatRow(stat: stats[i]),
              if (i < stats.length - 1)
                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 16),
                  child: HairDivider(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatDef {
  final String label;
  final String tag;
  final int value;
  const _StatDef({required this.label, required this.tag, required this.value});
}

class _StatRow extends StatelessWidget {
  final _StatDef stat;
  const _StatRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.tag,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            ArabicNumberUtils.toEasternArabic(stat.value),
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final AzkarStreaksState state;
  const _AchievementsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = <_AchievementDef>[
      _AchievementDef(
        icon: Icons.wb_sunny_outlined,
        label: 'أسبوع كامل',
        unlocked: state.currentStreak >= 7,
        accent: AppColors.secondary,
        background: AppColors.secondarySoft,
      ),
      _AchievementDef(
        icon: Icons.auto_awesome_outlined,
        label: '٣٠ يوماً متواصلاً',
        unlocked: state.currentStreak >= 30,
        accent: AppColors.primary,
        background: AppColors.primarySoft,
      ),
      _AchievementDef(
        icon: Icons.nightlight_outlined,
        label: 'قيام الليل ×٧',
        unlocked: false,
        accent: AppColors.ink3,
        background: AppColors.surfaceSunk,
      ),
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _AchievementCard(item: items[i])),
          if (i < items.length - 1) const SizedBox(width: AppSpacing.sm + 2),
        ],
      ],
    );
  }
}

class _AchievementDef {
  final IconData icon;
  final String label;
  final bool unlocked;
  final Color accent;
  final Color background;

  const _AchievementDef({
    required this.icon,
    required this.label,
    required this.unlocked,
    required this.accent,
    required this.background,
  });
}

class _AchievementCard extends StatelessWidget {
  final _AchievementDef item;
  const _AchievementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.unlocked ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: AppSpacing.md + 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.background,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, size: 18, color: item.accent),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  final AzkarStreaksState state;
  const _HeatmapCard({required this.state});

  static const _days = 90;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startDay = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: _days - 1));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اللون الداكن = صباح ومساء، الفاتح = أحدهما',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 3.0;
              const rows = 9;
              final cols = (_days / rows).ceil();
              final cell =
                  (constraints.maxWidth - (cols - 1) * gap) / cols;
              return SizedBox(
                height: rows * cell + (rows - 1) * gap,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Wrap(
                    direction: Axis.vertical,
                    spacing: gap,
                    runSpacing: gap,
                    children: List.generate(_days, (i) {
                      final day = startDay.add(Duration(days: i));
                      final m = state.didMorning(day);
                      final e = state.didEvening(day);
                      return Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: _cellColor(m, e),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _LegendSwatch(
                color: AppColors.surfaceSunk,
                label: 'لا شيء',
              ),
              const SizedBox(width: AppSpacing.md),
              _LegendSwatch(
                color: AppColors.primary.withValues(alpha: 0.4),
                label: 'جزئي',
              ),
              const SizedBox(width: AppSpacing.md),
              _LegendSwatch(
                color: AppColors.primary,
                label: 'كامل',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _cellColor(bool morning, bool evening) {
    if (morning && evening) return AppColors.primary;
    if (morning || evening) return AppColors.primary.withValues(alpha: 0.4);
    return AppColors.surfaceSunk;
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendSwatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: AppColors.ink3,
          ),
        ),
      ],
    );
  }
}
