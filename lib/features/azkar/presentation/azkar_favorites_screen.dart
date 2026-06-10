import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../domain/models/azkar_category.dart';
import 'providers/azkar_provider.dart';

class AzkarFavoritesScreen extends ConsumerWidget {
  const AzkarFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritedAzkarAsync = ref.watch(favoritedAzkarListProvider);
    final favorites = ref.watch(azkarFavoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'الأذكار المحفوظة',
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: favoritedAzkarAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'لا توجد أذكار مفضلة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'اضغط على ❤ عند قراءة الأذكار لإضافتها هنا',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final (category, dhikr) = items[index];
              final dhikrKey = '${category.id}:${dhikr.id}';
              final isFav = favorites.contains(dhikrKey);

              return _FavoriteDhikrCard(
                dhikr: dhikr,
                categoryName: category.nameAr,
                isFavorite: isFav,
                onToggleFavorite: () {
                  ref
                      .read(azkarFavoritesProvider.notifier)
                      .toggleFavorite(dhikrKey);
                },
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            'حدث خطأ في تحميل المفضلة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteDhikrCard extends StatelessWidget {
  final Dhikr dhikr;
  final String categoryName;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _FavoriteDhikrCard({
    required this.dhikr,
    required this.categoryName,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      elevation: 0,
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    categoryName,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                // Favorite toggle
                GestureDetector(
                  onTap: onToggleFavorite,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 24,
                    color:
                        isFavorite ? Colors.red.shade400 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Dhikr text
            Text(
              dhikr.textAr,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 19,
                height: 1.9,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Source + repetitions + actions
            Row(
              children: [
                if (dhikr.source.isNotEmpty)
                  Text(
                    dhikr.source,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),
                // Repetitions badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${ArabicNumberUtils.toEasternArabic(dhikr.repetitions)} مرة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Copy
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: dhikr.textAr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم النسخ', style: GoogleFonts.cairo()),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Share
                GestureDetector(
                  onTap: () {
                    Share.share('${dhikr.textAr}\n\n${dhikr.source}');
                  },
                  child: const Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
