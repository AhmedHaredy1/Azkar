import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'mushaf_screen.dart';
import 'providers/quran_audio_provider.dart';
import 'providers/quran_provider.dart';
import 'widgets/surah_list_tile.dart';

class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahListProvider);
    final lastReadPage = ref.watch(lastReadPageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'القرآن الكريم',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MushafScreen(initialPage: 0),
                ),
              );
            },
            tooltip: 'فتح المصحف',
          ),
        ],
      ),
      body: surahsAsync.when(
        data: (surahs) {
          if (surahs.isEmpty) {
            return Center(
              child: Text(
                'لا توجد بيانات',
                style: GoogleFonts.cairo(
                    fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }
          return Column(
            children: [
              // Mini audio player (when playing)
              _buildMiniPlayer(ref, surahs),
              // Open Mushaf button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MushafScreen(initialPage: lastReadPage),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book, size: 22),
                  label: Text(
                    lastReadPage > 1
                        ? 'متابعة القراءة - صفحة ${_toArabicNumber(lastReadPage)}'
                        : 'فتح المصحف',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: AppColors.divider.withValues(alpha: 0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'فهرس السور',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: AppColors.divider.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              // Surah list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: surahs.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 74,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return SurahListTile(
                      surah: surah,
                      onTap: () async {
                        final page = await ref
                            .read(quranLocalSourceProvider)
                            .getPageForSurah(surah.number);
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MushafScreen(initialPage: page),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل السور',
                style: GoogleFonts.cairo(
                    fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(surahListProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(WidgetRef ref, List surahs) {
    final audioState = ref.watch(quranAudioProvider);
    if (audioState.currentSurah == null) return const SizedBox.shrink();

    final surahIndex = audioState.currentSurah! - 1;
    final surahName = surahIndex >= 0 && surahIndex < surahs.length
        ? surahs[surahIndex].nameAr
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.headset, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'يستمع: $surahName - ${audioState.reciter.nameAr}',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (audioState.isPlaying) {
                ref.read(quranAudioProvider.notifier).pause();
              } else {
                ref.read(quranAudioProvider.notifier).resume();
              }
            },
            child: Icon(
              audioState.isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(quranAudioProvider.notifier).stop(),
            child: Icon(
              Icons.stop_circle_outlined,
              color: AppColors.textSecondary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  static String _toArabicNumber(int number) {
    const arabicDigits = [
      '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'
    ];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}
