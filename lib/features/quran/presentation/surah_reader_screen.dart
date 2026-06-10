import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import 'providers/quran_provider.dart';
import 'widgets/ayah_text_widget.dart';
import 'widgets/bismillah_header.dart';

class SurahReaderScreen extends ConsumerWidget {
  final int surahNumber;

  const SurahReaderScreen({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahProvider(surahNumber));

    return Scaffold(
      appBar: AppBar(
        title: surahAsync.when(
          data: (surah) => Text(
            surah?.nameAr ?? '',
            style: GoogleFonts.amiri(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          loading: () => const Text(''),
          error: (_, _) => const Text('خطأ'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final isBookmarked = ref.read(bookmarkProvider.notifier).isBookmarked(surahNumber, 1);
          ref.read(bookmarkProvider.notifier).toggleBookmark(surahNumber, 1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBookmarked ? 'تم إزالة العلامة' : 'تم حفظ العلامة',
                style: GoogleFonts.cairo(),
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        backgroundColor: AppColors.secondary,
        child: Icon(
          ref.read(bookmarkProvider.notifier).isBookmarked(surahNumber, 1)
              ? Icons.bookmark
              : Icons.bookmark_border,
          color: Colors.white,
        ),
      ),
      body: surahAsync.when(
        data: (surah) {
          if (surah == null || surah.ayahs.isEmpty) {
            return Center(
              child: Text(
                'لا توجد آيات',
                style: AppTextStyles.bodyText,
              ),
            );
          }

          // Surah 9 (At-Tawba) has no Bismillah
          final showBismillah = surah.number != 9;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: Column(
              children: [
                // Surah header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        surah.nameAr,
                        style: GoogleFonts.amiri(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${surah.ayahCount} آية',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bismillah
                if (showBismillah) const BismillahHeader(),
                if (!showBismillah) const SizedBox(height: AppSpacing.xl),
                // Ayahs
                ...surah.ayahs.map(
                  (ayah) => AyahTextWidget(ayah: ayah),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'حدث خطأ في تحميل السورة',
                style: GoogleFonts.cairo(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
