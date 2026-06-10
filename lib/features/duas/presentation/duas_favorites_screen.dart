import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../../core/widgets/ornaments.dart';
import '../domain/models/dua_category.dart';
import 'providers/duas_provider.dart';

class DuasFavoritesScreen extends ConsumerWidget {
  const DuasFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritedDuasAsync = ref.watch(favoritedDuasListProvider);
    final favorites = ref.watch(duaFavoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'المحفوظات',
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: favoritedDuasAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState();
          }

          // Group items by category name.
          final Map<String, List<(DuaCategory, Dua)>> grouped = {};
          for (final item in items) {
            grouped.putIfAbsent(item.$1.nameAr, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  '${ArabicNumberUtils.toEasternArabic(items.length)} عنصر محفوظ',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.ink3,
                  ),
                ),
              ),
              for (final entry in grouped.entries) ...[
                _GroupHeader(
                  label: entry.key,
                  count: entry.value.length,
                ),
                _GroupCard(
                  items: entry.value,
                  favorites: favorites,
                  onToggle: (key) =>
                      ref.read(duaFavoritesProvider.notifier).toggleFavorite(key),
                  onCopy: (text) {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم النسخ', style: GoogleFonts.cairo()),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  onShare: (dua) {
                    final shareText =
                        '${dua.textAr}\n\n${dua.source.isNotEmpty ? "المصدر: ${dua.source}" : ""}\n\nمن تطبيق رفيق المسلم';
                    Share.share(shareText);
                  },
                ),
                const SizedBox(height: AppSpacing.lg + 6),
              ],
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            'حدث خطأ في تحميل المحفوظات',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunk,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 28,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد محفوظات بعد',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            'اضغط على ♡ عند قراءة الأدعية لإضافتها هنا',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;

  const _GroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.ink3,
            ),
          ),
          Text(
            ArabicNumberUtils.toEasternArabic(count),
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<(DuaCategory, Dua)> items;
  final Set<String> favorites;
  final void Function(String key) onToggle;
  final void Function(String text) onCopy;
  final void Function(Dua dua) onShare;

  const _GroupCard({
    required this.items,
    required this.favorites,
    required this.onToggle,
    required this.onCopy,
    required this.onShare,
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
            for (int i = 0; i < items.length; i++) ...[
              _FavoriteRow(
                dua: items[i].$2,
                category: items[i].$1,
                favorited: favorites.contains(
                  '${items[i].$1.id}:${items[i].$2.id}',
                ),
                onToggle: () => onToggle(
                  '${items[i].$1.id}:${items[i].$2.id}',
                ),
                onCopy: () => onCopy(items[i].$2.textAr),
                onShare: () => onShare(items[i].$2),
              ),
              if (i < items.length - 1)
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

class _FavoriteRow extends StatelessWidget {
  final Dua dua;
  final DuaCategory category;
  final bool favorited;
  final VoidCallback onToggle;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _FavoriteRow({
    required this.dua,
    required this.category,
    required this.favorited,
    required this.onToggle,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 4,
        14,
        AppSpacing.md + 4,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.favorite_border_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dua.textAr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.amiri(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dua.source.isNotEmpty ? dua.source : category.nameAr,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onCopy,
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    GestureDetector(
                      onTap: onShare,
                      child: const Icon(
                        Icons.share_outlined,
                        size: 15,
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              favorited
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 16,
              color: favorited ? AppColors.secondary : AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}
