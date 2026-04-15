import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/models/dua_category.dart';
import '../providers/duas_provider.dart';

class DuaTextCard extends ConsumerWidget {
  final Dua dua;
  final int index;

  const DuaTextCard({
    super.key,
    required this.dua,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(duaFavoritesProvider);
    final duaKey = '${dua.categoryId}:${dua.id}';
    final isFavorite = favorites.contains(duaKey);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dua text
          Text(
            dua.textAr,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 20,
              height: 2.0,
              color: AppColors.textPrimary,
            ),
          ),
          if (dua.source.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              dua.source,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Favorite button
              IconButton(
                onPressed: () {
                  ref.read(duaFavoritesProvider.notifier).toggleFavorite(duaKey);
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                  color: isFavorite ? Colors.red.shade400 : AppColors.textSecondary,
                ),
                tooltip: 'المفضلة',
              ),
              const SizedBox(width: AppSpacing.sm),
              // Copy button
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: dua.textAr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم النسخ', style: GoogleFonts.cairo()),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.copy_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'نسخ',
              ),
              const SizedBox(width: AppSpacing.sm),
              // Share button
              IconButton(
                onPressed: () {
                  final shareText =
                      '${dua.textAr}\n\n${dua.source.isNotEmpty ? "المصدر: ${dua.source}" : ""}\n\nمن تطبيق حصن المسلم';
                  Share.share(shareText);
                },
                icon: const Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'مشاركة',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
