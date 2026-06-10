import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../core/widgets/ornaments.dart';

class Hadith {
  final String text;
  final String narrator;
  final String source;
  const Hadith({
    required this.text,
    required this.narrator,
    required this.source,
  });
  factory Hadith.fromJson(Map<String, dynamic> j) => Hadith(
        text: j['text'] as String,
        narrator: j['narrator'] as String,
        source: j['source'] as String,
      );
}

final hadithsProvider = FutureProvider<List<Hadith>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/hadiths.json');
  final List list = json.decode(raw) as List;
  return list
      .map((e) => Hadith.fromJson(e as Map<String, dynamic>))
      .toList();
});

final hadithOfDayProvider = Provider<AsyncValue<Hadith?>>((ref) {
  final async = ref.watch(hadithsProvider);
  return async.whenData((list) {
    if (list.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return list[dayOfYear % list.length];
  });
});

class HadithOfDayScreen extends ConsumerStatefulWidget {
  const HadithOfDayScreen({super.key});

  @override
  ConsumerState<HadithOfDayScreen> createState() => _HadithOfDayScreenState();
}

class _HadithOfDayScreenState extends ConsumerState<HadithOfDayScreen> {
  int _manualIndex = -1;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(hadithsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'حديث اليوم',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              final list = async.asData?.value ?? const <Hadith>[];
              if (list.isEmpty) return;
              setState(() {
                final base = _currentIndex(list.length);
                _manualIndex = (base + 1) % list.length;
              });
            },
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.ink2),
            tooltip: 'حديث آخر',
          ),
        ],
      ),
      body: async.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => const AppErrorView(
          message: 'تعذّر تحميل الأحاديث',
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'لا توجد أحاديث',
                style: GoogleFonts.cairo(color: AppColors.ink2),
              ),
            );
          }
          final index = _currentIndex(list.length);
          final h = list[index];
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
                Text(
                  _hijriToday(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md - 2),
                _HadithCard(
                  hadith: h,
                  number: index + 1,
                  onShare: () => _share(h),
                  onCopy: () => _copy(h),
                ),
                const SizedBox(height: AppSpacing.md + 2),
                Text(
                  'أحاديث سابقة',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                _PreviousList(
                  hadiths: list,
                  currentIndex: index,
                  onTap: (i) => setState(() => _manualIndex = i),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _currentIndex(int len) {
    if (_manualIndex >= 0) return _manualIndex % len;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return dayOfYear % len;
  }

  String _hijriToday() {
    final h = HijriCalendar.now();
    return '${ArabicNumberUtils.toEasternArabic(h.hDay)} ${h.longMonthName} ${ArabicNumberUtils.toEasternArabic(h.hYear)} هـ';
  }

  void _share(Hadith h) {
    Share.share(
      '${h.text}\n\nرواه ${h.narrator} — ${h.source}\n\n— من تطبيق رفيق المسلم',
    );
  }

  Future<void> _copy(Hadith h) async {
    await Clipboard.setData(
      ClipboardData(text: '${h.text}\n\nرواه ${h.narrator} — ${h.source}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الحديث')),
    );
  }
}

class _HadithCard extends StatelessWidget {
  final Hadith hadith;
  final int number;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  const _HadithCard({
    required this.hadith,
    required this.number,
    required this.onShare,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: GeoWatermark(
                size: 240,
                color: AppColors.primary,
                opacity: 0.05,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl - 2,
                AppSpacing.xl + 4,
                AppSpacing.xl - 2,
                AppSpacing.xl + 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SourcePill(source: hadith.source),
                  const SizedBox(height: AppSpacing.md + 2),
                  Text(
                    hadith.text,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      height: 2.0,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md + 2),
                  Container(height: 1, color: AppColors.hairline),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'الراوي',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hadith.narrator,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      height: 1.8,
                      color: AppColors.ink2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md + 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _IconAction(icon: Icons.copy_outlined, onTap: onCopy),
                          const SizedBox(width: AppSpacing.md + 2),
                          _IconAction(
                            icon: Icons.share_outlined,
                            onTap: onShare,
                          ),
                        ],
                      ),
                      Text(
                        'رقم ${ArabicNumberUtils.toEasternArabic(number)}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final String source;
  const _SourcePill({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarMark(size: 9, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            source,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: AppColors.ink2),
      ),
    );
  }
}

class _PreviousList extends StatelessWidget {
  final List<Hadith> hadiths;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PreviousList({
    required this.hadiths,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <_PreviousEntry>[];
    const labels = ['أمس', 'قبل يومين', 'قبل ٣ أيام'];
    for (var i = 0; i < 3 && i < hadiths.length - 1; i++) {
      final idx = (currentIndex - (i + 1) + hadiths.length) % hadiths.length;
      entries.add(_PreviousEntry(
        label: labels[i],
        hadith: hadiths[idx],
        index: idx,
      ));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            for (int i = 0; i < entries.length; i++) ...[
              InkWell(
                onTap: () => onTap(entries[i].index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md + 4,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entries[i].hadith.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.amiri(
                                fontSize: 15,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${entries[i].label} · ${entries[i].hadith.source}',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.chevron_left,
                        size: 16,
                        color: AppColors.ink3,
                      ),
                    ],
                  ),
                ),
              ),
              if (i < entries.length - 1)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md + 4,
                  ),
                  child: Container(height: 1, color: AppColors.hairline),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviousEntry {
  final String label;
  final Hadith hadith;
  final int index;
  const _PreviousEntry({
    required this.label,
    required this.hadith,
    required this.index,
  });
}
