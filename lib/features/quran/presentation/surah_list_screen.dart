import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/arabic_number_utils.dart';
import 'bookmarks_list_screen.dart';
import 'mushaf_screen.dart';
import 'providers/quran_audio_provider.dart';
import 'providers/quran_provider.dart';
import 'widgets/surah_list_tile.dart';

class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BookmarksListScreen(),
                ),
              );
            },
            tooltip: 'العلامات المرجعية',
          ),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'السور'),
            Tab(text: 'الأجزاء'),
          ],
        ),
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
              _buildMiniPlayer(surahs),
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
                        ? 'متابعة القراءة - صفحة ${ArabicNumberUtils.toEasternArabic(lastReadPage)}'
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
              // Tabbed content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSurahTab(surahs),
                    _buildJuzTab(),
                  ],
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

  Widget _buildSurahTab(List surahs) {
    return Column(
      children: [
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
            separatorBuilder: (_, _) => const Divider(
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
  }

  Widget _buildJuzTab() {
    final juzListAsync = ref.watch(juzListProvider);

    return juzListAsync.when(
      data: (juzList) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: juzList.length,
          separatorBuilder: (_, _) => const Divider(
            height: 1,
            indent: 74,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final juz = juzList[index];
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  ArabicNumberUtils.toEasternArabic(juz.juzNumber),
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              title: Text(
                'الجزء ${ArabicNumberUtils.toEasternArabic(juz.juzNumber)}',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'يبدأ من سورة ${juz.startSurahNameAr} - الآية ${ArabicNumberUtils.toEasternArabic(juz.startAyah)}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: Text(
                'ص ${ArabicNumberUtils.toEasternArabic(juz.startPage)}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MushafScreen(initialPage: juz.startPage),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text(
          'حدث خطأ في تحميل الأجزاء',
          style: GoogleFonts.cairo(
              fontSize: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(List surahs) {
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
}
