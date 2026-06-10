import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../../core/widgets/ornaments.dart';
import '../domain/models/dua_category.dart';
import 'providers/duas_provider.dart';

class DuasCategoriesScreen extends ConsumerWidget {
  const DuasCategoriesScreen({super.key});

  IconData _iconFor(String id, String nameAr) {
    final key = '$id $nameAr'.toLowerCase();
    if (key.contains('sabah') ||
        nameAr.contains('الصباح') ||
        nameAr.contains('المساء')) {
      return Icons.wb_sunny_outlined;
    }
    if (nameAr.contains('قرآن') || nameAr.contains('القران')) {
      return Icons.menu_book_rounded;
    }
    if (nameAr.contains('طعام') || nameAr.contains('شراب')) {
      return Icons.restaurant_menu_rounded;
    }
    if (nameAr.contains('سفر') || nameAr.contains('خروج')) {
      return Icons.location_on_outlined;
    }
    if (nameAr.contains('كرب') || nameAr.contains('حزن')) {
      return Icons.favorite_border_rounded;
    }
    if (nameAr.contains('استغفار') || nameAr.contains('توبة')) {
      return Icons.nightlight_outlined;
    }
    if (nameAr.contains('نوم') || nameAr.contains('استيقاظ')) {
      return Icons.bedtime_outlined;
    }
    if (nameAr.contains('صلاة') || nameAr.contains('صلوات')) {
      return Icons.mosque_rounded;
    }
    return Icons.auto_awesome_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(duasCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'الأدعية',
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, size: 22),
            color: AppColors.ink2,
            onPressed: () => context.push('/duas/favorites'),
            tooltip: 'المحفوظة',
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Text(
                'لا توجد أدعية',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.ink3,
                ),
              ),
            );
          }
          final totalDuas = categories.fold<int>(
            0,
            (sum, c) => sum + c.duasList.length,
          );
          final featured = _pickFeatured(categories);
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _SubHeader(
                count: totalDuas,
                categories: categories.length,
              ),
              if (featured != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _FeaturedCard(dua: featured.$2, category: featured.$1),
              ],
              const SizedBox(height: AppSpacing.xl - 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm + 2,
                ),
                child: Text(
                  'التصنيفات',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: AppColors.ink3,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl,
                ),
                child: _CategoriesCard(
                  categories: categories,
                  onTap: (id) => context.push('/duas/$id'),
                  iconResolver: _iconFor,
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 40, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'حدث خطأ في تحميل الأدعية',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref.invalidate(duasCategoriesProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (DuaCategory, Dua)? _pickFeatured(List<DuaCategory> categories) {
    for (final cat in categories) {
      if (cat.duasList.isNotEmpty) {
        final day = DateTime.now().day;
        final idx = day % cat.duasList.length;
        return (cat, cat.duasList[idx]);
      }
    }
    return null;
  }
}

class _SubHeader extends StatelessWidget {
  final int count;
  final int categories;

  const _SubHeader({required this.count, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md,
      ),
      child: Text(
        '${ArabicNumberUtils.toEasternArabic(count)} دعاء في ${ArabicNumberUtils.toEasternArabic(categories)} تصنيفات',
        style: GoogleFonts.cairo(
          fontSize: 12,
          color: AppColors.ink3,
        ),
      ),
    );
  }
}

class _FeaturedCard extends ConsumerWidget {
  final Dua dua;
  final DuaCategory category;

  const _FeaturedCard({required this.dua, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duaKey = '${category.id}:${dua.id}';
    final isFavorite = ref.watch(duaFavoritesProvider).contains(duaKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.hairline),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: GeoWatermark(
                  size: 200,
                  color: AppColors.primary,
                  opacity: 0.04,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'دعاء اليوم',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    dua.textAr,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.amiri(
                      fontSize: 21,
                      height: 1.9,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(height: 1, color: AppColors.hairline),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dua.source.isNotEmpty ? dua.source : category.nameAr,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: dua.textAr));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم نسخ الدعاء',
                                style: GoogleFonts.cairo(),
                              ),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.copy_rounded,
                              size: 18, color: AppColors.ink2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          ref
                              .read(duaFavoritesProvider.notifier)
                              .toggleFavorite(duaKey);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFavorite
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                            color: isFavorite
                                ? AppColors.secondary
                                : AppColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  final List<DuaCategory> categories;
  final void Function(String id) onTap;
  final IconData Function(String id, String nameAr) iconResolver;

  const _CategoriesCard({
    required this.categories,
    required this.onTap,
    required this.iconResolver,
  });

  @override
  Widget build(BuildContext context) {
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
            for (int i = 0; i < categories.length; i++) ...[
              _CategoryRow(
                category: categories[i],
                icon: iconResolver(categories[i].id, categories[i].nameAr),
                onTap: () => onTap(categories[i].id),
              ),
              if (i < categories.length - 1)
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

class _CategoryRow extends StatelessWidget {
  final DuaCategory category;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.category,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 4,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                category.nameAr,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              ArabicNumberUtils.toEasternArabic(category.duasList.length),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.ink3,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: AppColors.ink4,
            ),
          ],
        ),
      ),
    );
  }
}
