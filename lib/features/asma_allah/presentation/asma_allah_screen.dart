import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../core/widgets/ornaments.dart';

class AsmaName {
  final int index;
  final String name;
  final String translit;
  final String meaning;
  const AsmaName({
    required this.index,
    required this.name,
    required this.translit,
    required this.meaning,
  });
  factory AsmaName.fromJson(Map<String, dynamic> j) => AsmaName(
        index: j['index'] as int,
        name: j['name'] as String,
        translit: j['translit'] as String,
        meaning: j['meaning'] as String,
      );
}

final asmaAllahProvider = FutureProvider<List<AsmaName>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/asma_allah.json');
  final List list = json.decode(raw) as List;
  return list
      .map((e) => AsmaName.fromJson(e as Map<String, dynamic>))
      .toList();
});

class AsmaAllahScreen extends ConsumerWidget {
  const AsmaAllahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asmaAsync = ref.watch(asmaAllahProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'أسماء الله الحسنى',
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
      body: asmaAsync.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => AppErrorView(
          message: 'تعذّر تحميل أسماء الله الحسنى',
          onRetry: () => ref.invalidate(asmaAllahProvider),
        ),
        data: (names) {
          if (names.isEmpty) {
            return const AppEmptyView(
              message: 'لا توجد بيانات متاحة',
              icon: Icons.auto_awesome_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            itemCount: names.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _Hero(total: names.length),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                child: _NameRow(
                  name: names[i - 1],
                  onTap: () => _showDetail(context, names[i - 1]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, AsmaName n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 1.2),
              ),
              child: Text(
                ArabicNumberUtils.toEasternArabic(n.index),
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              n.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              n.translit,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.ink3,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              height: 1,
              color: AppColors.hairline,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              n.meaning,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                height: 1.8,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'تم',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final int total;
  const _Hero({required this.total});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg + 4),
        decoration: BoxDecoration(
          color: AppColors.parchmentDeep,
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -60,
              left: -60,
              child: GeoWatermark(
                size: 220,
                color: AppColors.secondary,
                opacity: 0.1,
              ),
            ),
            Column(
              children: [
                Text(
                  'الأسماء الحسنى',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Text(
                  'وَلِلّٰهِ الْأَسْمَاءُ الْحُسْنَىٰ فَادْعُوهُ بِهَا',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 1,
                  color: AppColors.secondary.withValues(alpha: 0.2),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        value: ArabicNumberUtils.toEasternArabic(total),
                        label: 'اسماً',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: AppColors.secondary.withValues(alpha: 0.2),
                    ),
                    const Expanded(
                      child: _HeroStat(
                        value: '٩٩',
                        label: 'مباركة',
                      ),
                    ),
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

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
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

class _NameRow extends StatelessWidget {
  final AsmaName name;
  final VoidCallback onTap;
  const _NameRow({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 1),
              ),
              child: Text(
                ArabicNumberUtils.toEasternArabic(name.index),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          name.name,
                          style: GoogleFonts.amiri(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          name.translit,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name.meaning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_left, size: 18, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}
