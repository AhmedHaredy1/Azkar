import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import 'mushaf_screen.dart';
import 'providers/quran_provider.dart';

class BookmarksListScreen extends ConsumerWidget {
  const BookmarksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkProvider);
    final surahsAsync = ref.watch(surahListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'العلامات المرجعية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      body: bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'لا توجد علامات مرجعية',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'اضغط مطولاً على آية في المصحف لإضافة علامة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : surahsAsync.when(
              data: (surahs) {
                // Sort bookmarks by creation date (newest first)
                final sortedBookmarks = List.of(bookmarks)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  itemCount: sortedBookmarks.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 74,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final bookmark = sortedBookmarks[index];
                    // Find surah name
                    String surahName = '';
                    int page = 1;
                    try {
                      final surah = surahs.firstWhere(
                        (s) => s.number == bookmark.surahNumber,
                      );
                      surahName = surah.nameAr;
                      // Get the page for this ayah
                      for (final ayah in surah.ayahs) {
                        if (ayah.number == bookmark.ayahNumber) {
                          page = ayah.page;
                          break;
                        }
                      }
                    } catch (_) {
                      surahName = 'سورة ${bookmark.surahNumber}';
                    }

                    final dateFormatted =
                        DateFormat('yyyy/MM/dd', 'ar').format(bookmark.createdAt);

                    return Dismissible(
                      key: Key(bookmark.key),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        color: AppColors.error,
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) {
                        ref.read(bookmarkProvider.notifier).toggleBookmark(
                              bookmark.surahNumber,
                              bookmark.ayahNumber,
                            );
                      },
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.bookmark,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          '$surahName - الآية ${ArabicNumberUtils.toEasternArabic(bookmark.ayahNumber)}',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'صفحة ${ArabicNumberUtils.toEasternArabic(page)} • $dateFormatted',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_left,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MushafScreen(initialPage: page),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, _) => Center(
                child: Text(
                  'حدث خطأ',
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
