import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/tokens.dart';

/// Persisted Khatma plan state — start date, target days, and the count of
/// completed pages. Stored in the shared `settings` Hive box under fixed keys
/// so we don't need a new box.
class KhatmaState {
  final DateTime? startDate;
  final int targetDays; // 30 or 60 typically
  final int pagesRead; // 0..604

  const KhatmaState({
    this.startDate,
    this.targetDays = 30,
    this.pagesRead = 0,
  });

  static const totalPages = 604;

  bool get hasPlan => startDate != null;
  bool get isComplete => pagesRead >= totalPages;
  double get progress => (pagesRead / totalPages).clamp(0.0, 1.0);

  /// Pages-per-day target derived from the plan length.
  int get pagesPerDay => (totalPages / targetDays).ceil();

  int get expectedPagesByNow {
    if (startDate == null) return 0;
    final daysElapsed =
        DateTime.now().difference(startDate!).inDays + 1;
    return (daysElapsed * pagesPerDay).clamp(0, totalPages);
  }

  /// Positive = ahead, negative = behind.
  int get pagesAheadOrBehind => pagesRead - expectedPagesByNow;

  KhatmaState copyWith({
    DateTime? startDate,
    int? targetDays,
    int? pagesRead,
    bool clearStart = false,
  }) {
    return KhatmaState(
      startDate: clearStart ? null : (startDate ?? this.startDate),
      targetDays: targetDays ?? this.targetDays,
      pagesRead: pagesRead ?? this.pagesRead,
    );
  }
}

class KhatmaNotifier extends StateNotifier<KhatmaState> {
  final StorageService _storage;

  KhatmaNotifier(this._storage) : super(const KhatmaState()) {
    _load();
  }

  void _load() {
    final startMs = _storage.getSetting<int>('khatmaStartMs');
    final target = _storage.getSetting<int>('khatmaTargetDays', defaultValue: 30) ?? 30;
    final pages = _storage.getSetting<int>('khatmaPagesRead', defaultValue: 0) ?? 0;
    state = KhatmaState(
      startDate:
          startMs != null ? DateTime.fromMillisecondsSinceEpoch(startMs) : null,
      targetDays: target,
      pagesRead: pages,
    );
  }

  Future<void> startPlan(int targetDays) async {
    final now = DateTime.now();
    state = KhatmaState(
      startDate: now,
      targetDays: targetDays,
      pagesRead: 0,
    );
    await _storage.putSetting('khatmaStartMs', now.millisecondsSinceEpoch);
    await _storage.putSetting('khatmaTargetDays', targetDays);
    await _storage.putSetting('khatmaPagesRead', 0);
  }

  Future<void> recordPagesToday(int pages) async {
    final newTotal = (state.pagesRead + pages).clamp(0, KhatmaState.totalPages);
    state = state.copyWith(pagesRead: newTotal);
    await _storage.putSetting('khatmaPagesRead', newTotal);
  }

  Future<void> resetPlan() async {
    state = const KhatmaState();
    await _storage.deleteSetting('khatmaStartMs');
    await _storage.deleteSetting('khatmaTargetDays');
    await _storage.deleteSetting('khatmaPagesRead');
  }
}

final khatmaProvider =
    StateNotifierProvider<KhatmaNotifier, KhatmaState>((ref) {
  return KhatmaNotifier(ref.watch(storageServiceProvider));
});

class KhatmaScreen extends ConsumerWidget {
  const KhatmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(khatmaProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ختمة القرآن',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: state.hasPlan
          ? _ActivePlan(state: state)
          : const _NoPlan(),
    );
  }
}

class _NoPlan extends ConsumerWidget {
  const _NoPlan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ابدأ خطة ختمة القرآن',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'اختر عدد الأيام لإتمام القرآن الكريم',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _PlanOption(
            days: 30,
            description: '٢٠ صفحة في اليوم — جزء واحد',
            color: AppColors.primary,
            onTap: () => ref.read(khatmaProvider.notifier).startPlan(30),
          ),
          const SizedBox(height: AppSpacing.md),
          _PlanOption(
            days: 60,
            description: '١٠ صفحات في اليوم — نصف جزء',
            color: const Color(0xFF00838F),
            onTap: () => ref.read(khatmaProvider.notifier).startPlan(60),
          ),
          const SizedBox(height: AppSpacing.md),
          _PlanOption(
            days: 90,
            description: '٧ صفحات في اليوم تقريباً',
            color: const Color(0xFF6A1B9A),
            onTap: () => ref.read(khatmaProvider.notifier).startPlan(90),
          ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final int days;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _PlanOption({
    required this.days,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$days',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ختمة في $days يوماً',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: color),
          ],
        ),
      ),
    );
  }
}

class _ActivePlan extends ConsumerStatefulWidget {
  final KhatmaState state;
  const _ActivePlan({required this.state});

  @override
  ConsumerState<_ActivePlan> createState() => _ActivePlanState();
}

class _ActivePlanState extends ConsumerState<_ActivePlan> {
  int _todayPages = 0;

  @override
  void initState() {
    super.initState();
    _todayPages = widget.state.pagesPerDay;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final ahead = s.pagesAheadOrBehind;
    final statusColor = s.isComplete
        ? AppColors.primary
        : ahead >= 0
            ? AppColors.primary
            : Colors.orange;
    final statusText = s.isComplete
        ? 'تمت الختمة — تقبّل الله'
        : ahead >= 0
            ? 'متقدّم بـ $ahead صفحة'
            : 'متأخّر بـ ${ahead.abs()} صفحة';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, const Color(0xFF388E3C)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Text(
                  '${s.pagesRead} / ${KhatmaState.totalPages}',
                  style: GoogleFonts.amiri(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'صفحة من القرآن الكريم',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: s.progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${(s.progress * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatRow(s: s, statusText: statusText, statusColor: statusColor),
          const SizedBox(height: AppSpacing.lg),
          if (!s.isComplete) ...[
            Text(
              'سجّل الصفحات التي قرأتها اليوم',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                IconButton.outlined(
                  onPressed: () => setState(() {
                    _todayPages = (_todayPages - 1).clamp(1, 50);
                  }),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_todayPages صفحة',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => setState(() {
                    _todayPages = (_todayPages + 1).clamp(1, 50);
                  }),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () async {
                await ref
                    .read(khatmaProvider.notifier)
                    .recordPagesToday(_todayPages);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تسجيل $_todayPages صفحة'),
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('سجّل القراءة'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context.push('/quran'),
              icon: const Icon(Icons.menu_book),
              label: const Text('افتح المصحف'),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('إعادة تعيين الخطة',
                      style: GoogleFonts.cairo()),
                  content: Text(
                    'سيتم حذف تقدّم الختمة الحالي. هل أنت متأكد؟',
                    style: GoogleFonts.cairo(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(khatmaProvider.notifier).resetPlan();
              }
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text(
              'إعادة تعيين الخطة',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final KhatmaState s;
  final String statusText;
  final Color statusColor;

  const _StatRow({
    required this.s,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            label: 'الهدف اليومي',
            value: '${s.pagesPerDay} صفحة',
            icon: Icons.flag_outlined,
            color: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCell(
            label: 'مدة الخطة',
            value: '${s.targetDays} يوم',
            icon: Icons.calendar_today,
            color: const Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCell(
            label: 'الحالة',
            value: statusText,
            icon: Icons.trending_up,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
