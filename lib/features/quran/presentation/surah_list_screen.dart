import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../../core/widgets/ornaments.dart';
import '../../mushaf/domain/models/mushaf_type.dart';
import '../../mushaf/presentation/providers/mushaf_provider.dart';
import 'providers/quran_audio_provider.dart';
import 'providers/quran_provider.dart';
import 'widgets/quran_search_dialog.dart';
import 'widgets/surah_list_tile.dart';

class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

enum _QuranFilter { surahs, juz, bookmarks }

class _SurahListScreenState extends ConsumerState<SurahListScreen> {
  _QuranFilter _filter = _QuranFilter.surahs;

  /// The mushaf the PDF reader opens, or null after showing the
  /// "download one first" snackbar.
  Future<MushafType?> _resolveActiveMushaf() async {
    final mushaf = await ref.read(activeMushafProvider.future);
    if (mushaf == null && mounted) {
      // Lightweight, non-blocking notice: auto-dismisses after 3 seconds,
      // no interaction required. The action deep-links to the library.
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          content: Text(
            'لا يوجد مصحف محمّل. قم بتحميل مصحف أولاً.',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.right,
          ),
          action: SnackBarAction(
            label: 'تحميل المصاحف',
            onPressed: () {
              if (mounted) context.push('/mushaf-library');
            },
          ),
        ),
      );
    }
    return mushaf;
  }

  Future<void> _openMushafPdf({int? surahNumber}) async {
    final mushaf = await _resolveActiveMushaf();
    if (mushaf == null || !mounted) return;

    // Without `page` the PDF route resumes from the per-mushaf saved page.
    final query = surahNumber != null
        ? '?page=${mushaf.getSurahStartPage(surahNumber)}'
        : '';
    context.push('/mushaf-pdf/${mushaf.id}$query');
  }

  void _openSurah(int surahNumber) async {
    final mode = ref.read(quranReadingModeProvider);
    if (mode == 'mushaf') {
      await _openMushafPdf(surahNumber: surahNumber);
    } else {
      final page = await ref
          .read(quranLocalSourceProvider)
          .getPageForSurah(surahNumber);
      if (mounted) {
        context.push('/mushaf-text?page=$page');
      }
    }
  }

  void _openContinueReading(int lastPage) {
    final mode = ref.read(quranReadingModeProvider);
    if (mode == 'mushaf') {
      _openMushafPdf();
    } else {
      context.push('/mushaf-text?page=$lastPage');
    }
  }

  void _showQuranSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranSearchDialog(onGoToPage: _openSearchResultPage),
    );
  }

  /// Open a search result. The search dialog works in the standard 604-page
  /// text layout; in PDF mode the page is mapped into the active mushaf.
  Future<void> _openSearchResultPage(int textPage) async {
    final mode = ref.read(quranReadingModeProvider);
    if (mode != 'mushaf') {
      context.push('/mushaf-text?page=$textPage');
      return;
    }
    final mushaf = await _resolveActiveMushaf();
    if (mushaf == null || !mounted) return;
    final pdfPage = await _textPageToPdfPage(textPage, mushaf);
    if (mounted) {
      context.push('/mushaf-pdf/${mushaf.id}?page=$pdfPage');
    }
  }

  /// Map a standard 604-layout text page into a PDF page of [mushaf]:
  /// exact at surah starts, proportional within the surah's span. For the
  /// Madinah-layout mushafs this resolves to the identical printed page.
  Future<int> _textPageToPdfPage(int textPage, MushafType mushaf) async {
    try {
      final pageIndex = await ref.read(pageIndexProvider.future);
      final surah =
          pageIndex[textPage]?.sections.firstOrNull?.surahNumber ?? 1;
      final src = ref.read(quranLocalSourceProvider);
      final textStart = await src.getPageForSurah(surah);
      var textEnd = 604;
      if (surah < 114) {
        textEnd = await src.getPageForSurah(surah + 1) - 1;
        if (textEnd < textStart) textEnd = textStart;
      }
      final pdfStart = mushaf.getSurahStartPage(surah);
      final pdfEnd = mushaf.getSurahEndPage(surah);
      final span = textEnd - textStart;
      final frac =
          span <= 0 ? 0.0 : ((textPage - textStart) / span).clamp(0.0, 1.0);
      return (pdfStart + frac * (pdfEnd - pdfStart))
          .round()
          .clamp(1, mushaf.totalPdfPages);
    } catch (_) {
      // Front-matter offset alone is a close fallback for the wide mushafs.
      return mushaf.pdfPageFromMushaf(textPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahListProvider);
    final lastReadPage = ref.watch(lastReadPageProvider);
    final readingMode = ref.watch(quranReadingModeProvider);

    // Continue-reading position is mode-specific: text mode tracks the
    // 604-page text layout, mushaf mode tracks the active PDF's own saved
    // page — the two never overwrite each other.
    var continuePage = lastReadPage;
    var continueTotal = 604;
    String? continueMushafName;
    if (readingMode == 'mushaf') {
      final active = ref.watch(activeMushafProvider).valueOrNull;
      if (active != null) {
        final pdfPage = ref.watch(lastPdfPageProvider(active.id));
        continuePage = active.mushafPageFromPdf(pdfPage);
        continueTotal = active.totalMushafPages;
        continueMushafName = active.nameAr;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: surahsAsync.when(
          data: (surahs) {
            if (surahs.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد بيانات',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.ink3,
                  ),
                ),
              );
            }
            return Column(
              children: [
                _MiniPlayerBar(surahs: surahs),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TitleRow(
                                onBookmarks: () =>
                                    context.push('/quran-bookmarks'),
                                onSearch: _showQuranSearch,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _ContinueReadingCard(
                                lastPage: continuePage,
                                totalPages: continueTotal,
                                mushafName: continueMushafName,
                                onTap: () => _openContinueReading(lastReadPage),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _ReadingModeRow(
                                mode: readingMode,
                                onModeChange: (m) {
                                  ref
                                      .read(mushafActionProvider.notifier)
                                      .setReadingMode(m);
                                },
                                onLibrary: () =>
                                    context.push('/mushaf-library'),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _FilterRow(
                                filter: _filter,
                                onChange: (f) => setState(() => _filter = f),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        ),
                      ),
                      _buildBody(surahs),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xl),
                      ),
                    ],
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
                const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppColors.ink3,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'حدث خطأ في تحميل السور',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => ref.invalidate(surahListProvider),
                  child: Text(
                    'إعادة المحاولة',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List surahs) {
    switch (_filter) {
      case _QuranFilter.surahs:
        // Lazy sliver: only visible tiles are built/laid out. DecoratedSliver
        // keeps the single rounded-card look without materializing all 114
        // rows up front.
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            sliver: SliverList.separated(
              itemCount: surahs.length,
              itemBuilder: (context, i) => SurahListTile(
                surah: surahs[i],
                onTap: () => _openSurah(surahs[i].number),
              ),
              separatorBuilder: (context, i) => const Padding(
                padding: EdgeInsetsDirectional.only(start: 62),
                child: HairDivider(),
              ),
            ),
          ),
        );
      case _QuranFilter.juz:
        return _buildJuzSliver();
      case _QuranFilter.bookmarks:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 40,
                  color: AppColors.ink3,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'عرض المفضلة في شاشة منفصلة',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => context.push('/quran-bookmarks'),
                  child: Text(
                    'فتح المفضلة',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildJuzSliver() {
    final juzListAsync = ref.watch(juzListProvider);
    return juzListAsync.when(
      data: (juzList) {
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            sliver: SliverList.separated(
              itemCount: juzList.length,
              itemBuilder: (context, i) => _JuzTile(
                juz: juzList[i],
                onTap: () => _openSurah(juzList[i].startSurah),
              ),
              separatorBuilder: (context, i) => const Padding(
                padding: EdgeInsetsDirectional.only(start: 62),
                child: HairDivider(),
              ),
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'تعذّر تحميل الأجزاء',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 13, color: AppColors.ink3),
          ),
        ),
      ),
    );
  }
}

class _JuzTile extends StatelessWidget {
  final JuzInfo juz;
  final VoidCallback onTap;

  const _JuzTile({required this.juz, required this.onTap});

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
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: Text(
                ArabicNumberUtils.toEasternArabic(juz.juzNumber),
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الجزء ${ArabicNumberUtils.toEasternArabic(juz.juzNumber)}',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'يبدأ من ${juz.startSurahNameAr} · آية ${ArabicNumberUtils.toEasternArabic(juz.startAyah)}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'ص ${ArabicNumberUtils.toEasternArabic(juz.startPage)}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: AppColors.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final VoidCallback onBookmarks;
  final VoidCallback onSearch;

  const _TitleRow({required this.onBookmarks, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'المصحف',
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        Row(
          children: [
            _PillIconButton(
              icon: Icons.search_rounded,
              onTap: onSearch,
            ),
            const SizedBox(width: AppSpacing.sm),
            _PillIconButton(
              icon: Icons.bookmark_border_rounded,
              onTap: onBookmarks,
            ),
          ],
        ),
      ],
    );
  }
}

class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PillIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Material + InkWell for ripple feedback; 40px meets comfortable
    // touch-target sizing while keeping the compact pill look.
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.hairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 16, color: AppColors.ink2),
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends ConsumerWidget {
  final int lastPage;
  final int totalPages;
  final String? mushafName;
  final VoidCallback onTap;

  const _ContinueReadingCard({
    required this.lastPage,
    required this.onTap,
    this.totalPages = 604,
    this.mushafName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = (lastPage / totalPages).clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    return Material(
      color: AppColors.parchmentDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.parchmentBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: GeoWatermark(
                opacity: 0.12,
                color: AppColors.secondary,
                size: 220,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    StarMark(size: 10, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'متابعة القراءة',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  lastPage > 1 ? 'صفحة ${ArabicNumberUtils.toEasternArabic(lastPage)}' : 'ابدأ القراءة',
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastPage > 1
                      ? 'من ${ArabicNumberUtils.toEasternArabic(totalPages)} صفحة'
                          '${mushafName != null ? ' · $mushafName' : ''}'
                      : 'اضغط لفتح المصحف',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.ink2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Stack(
                          children: [
                            Container(
                              height: 4,
                              color: const Color(0x2EB8892A),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 4,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$pct%',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
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

class _FilterRow extends StatelessWidget {
  final _QuranFilter filter;
  final ValueChanged<_QuranFilter> onChange;

  const _FilterRow({required this.filter, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final entries = [
      (_QuranFilter.surahs, 'السور'),
      (_QuranFilter.juz, 'الأجزاء'),
      (_QuranFilter.bookmarks, 'المفضلة'),
    ];
    return Row(
      children: [
        for (final e in entries) ...[
          Material(
            color: filter == e.$1 ? AppColors.ink : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: BorderSide(
                color: filter == e.$1 ? AppColors.ink : AppColors.hairline,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onChange(e.$1),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight:
                      filter == e.$1 ? FontWeight.w600 : FontWeight.w400,
                  color: filter == e.$1 ? Colors.white : AppColors.ink2,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md + 2,
                    vertical: 7,
                  ),
                  child: Text(e.$2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _ReadingModeRow extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onModeChange;
  final VoidCallback onLibrary;

  const _ReadingModeRow({
    required this.mode,
    required this.onModeChange,
    required this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Row(
              children: [
                _ModeTab(
                  label: 'نصّي',
                  icon: Icons.text_fields_rounded,
                  isActive: mode == 'text',
                  onTap: () => onModeChange('text'),
                ),
                _ModeTab(
                  label: 'مصحف مصوّر',
                  icon: Icons.menu_book_rounded,
                  isActive: mode == 'mushaf',
                  onTap: () => onModeChange('mushaf'),
                ),
              ],
            ),
          ),
        ),
        if (mode == 'mushaf') ...[
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onLibrary,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: Icon(
                Icons.library_books_rounded,
                size: 16,
                color: AppColors.ink2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isActive ? Colors.white : AppColors.ink3,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : AppColors.ink3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerBar extends ConsumerWidget {
  final List surahs;
  const _MiniPlayerBar({required this.surahs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(quranAudioProvider);
    if (audioState.currentSurah == null) return const SizedBox.shrink();

    final surahIndex = audioState.currentSurah! - 1;
    final surahName = surahIndex >= 0 && surahIndex < surahs.length
        ? surahs[surahIndex].nameAr
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        border: const Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.headset_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              'يستمع: $surahName · ${audioState.reciter.nameAr}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.ink,
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
              audioState.isPlaying
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: () => ref.read(quranAudioProvider.notifier).stop(),
            child: const Icon(
              Icons.stop_circle_outlined,
              color: AppColors.ink3,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
