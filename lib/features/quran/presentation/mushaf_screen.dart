import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import 'providers/quran_audio_provider.dart';
import 'providers/quran_provider.dart';
import 'widgets/mushaf_page_widget.dart';
import 'widgets/quran_audio_bar.dart';
import 'widgets/quran_search_dialog.dart';

class MushafScreen extends ConsumerStatefulWidget {
  final int initialPage;

  const MushafScreen({super.key, this.initialPage = 0});

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 1;
  bool _showControls = false;
  late AnimationController _controlsAnimController;
  late Animation<double> _controlsFade;
  String _currentSurahName = '';
  final FocusNode _focusNode = FocusNode();
  bool _showAudioBar = false;

  String _toArabicNumber(int number) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  bool _restoredHighlight = false;

  @override
  void initState() {
    super.initState();
    final startPage = widget.initialPage > 0 ? widget.initialPage : 1;
    _currentPage = startPage;
    _pageController = PageController(initialPage: startPage - 1);

    _controlsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _controlsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controlsAnimController, curve: Curves.easeInOut),
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlsAnimController.dispose();
    _focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 1 || page > 604) return;
    _pageController.jumpToPage(page - 1);
    setState(() => _currentPage = page);
  }

  // In RTL context (no reverse), PageView index increases left-to-right,
  // so nextPage() = swipe left = higher page number = correct Mushaf direction.
  void _nextPage() {
    if (_currentPage < 604) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    // RTL: Left arrow = next page (higher number), Right arrow = previous page
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _nextPage();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _previousPage();
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsAnimController.forward();
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _showControls) {
          setState(() => _showControls = false);
          _controlsAnimController.reverse();
        }
      });
    } else {
      _controlsAnimController.reverse();
    }
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuranSearchDialog(onGoToPage: _goToPage),
    );
  }

  void _updateSurahName(Map<int, dynamic> pages) {
    final p = pages[_currentPage];
    if (p != null && p.sections.isNotEmpty) {
      _currentSurahName = p.sections.last.surahNameAr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(pageIndexProvider);

    // Auto-navigate to page when audio moves to a different page
    final audioState = ref.watch(quranAudioProvider);
    if (audioState.isPlaying && audioState.playingAyah != null) {
      final targetPage = audioState.playingAyah!.page;
      if (targetPage != _currentPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _goToPage(targetPage);
        });
      }
    }

    // Restore to highlighted ayah page first, otherwise last read page
    final highlighted = ref.watch(highlightedAyahProvider);
    if (widget.initialPage <= 0 && !_restoredHighlight) {
      _restoredHighlight = true;
      if (highlighted != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _goToPage(highlighted.page));
      } else {
        final lastRead = ref.watch(lastReadPageProvider);
        if (lastRead > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _goToPage(lastRead));
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyPress,
        child: pagesAsync.when(
          data: (pages) {
            if (pages.isEmpty) {
              return Center(
                child: Text('لا توجد بيانات', style: GoogleFonts.cairo(fontSize: 16)),
              );
            }

            _updateSurahName(pages);

            return Stack(
              children: [
                // ===== MUSHAF PAGE VIEW =====
                PageView.builder(
                  controller: _pageController,
                  itemCount: 604,
                  onPageChanged: (index) {
                    final page = index + 1;
                    setState(() {
                      _currentPage = page;
                      _updateSurahName(pages);
                    });
                    ref.read(lastReadPageProvider.notifier).setPage(page);
                  },
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;
                    final quranPage = pages[pageNum];
                    if (quranPage == null) {
                      return Container(
                        color: const Color(0xFFFFF8EC),
                        child: Center(
                          child: Text(
                            'صفحة ${_toArabicNumber(pageNum)}',
                            style: GoogleFonts.amiri(fontSize: 18),
                          ),
                        ),
                      );
                    }
                    return MushafPageWidget(
                      page: quranPage,
                      onToggleControls: _toggleControls,
                    );
                  },
                ),

                // ===== NAVIGATION ARROWS (always visible, subtle) =====
                // Right arrow (previous page = lower page number)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _previousPage,
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.chevron_right,
                        color: const Color(0xFFB8860B).withValues(alpha: 0.3),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                // Left arrow (next page = higher page number)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _nextPage,
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.chevron_left,
                        color: const Color(0xFFB8860B).withValues(alpha: 0.3),
                        size: 30,
                      ),
                    ),
                  ),
                ),

                // ===== CONTROLS OVERLAY =====
                if (_showControls) ...[
                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _controlsFade,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1810).withValues(alpha: 0.92),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _currentSurahName,
                                        style: GoogleFonts.amiri(
                                          color: const Color(0xFFD4A017),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'صفحة ${_toArabicNumber(_currentPage)} | الجزء ${_toArabicNumber(pages[_currentPage]?.juz ?? 1)}',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.search, color: Colors.white, size: 22),
                                  onPressed: _showSearch,
                                  tooltip: 'بحث',
                                ),
                                IconButton(
                                  icon: Icon(
                                    _showAudioBar ? Icons.headset_off : Icons.headset,
                                    color: const Color(0xFFD4A017),
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() => _showAudioBar = !_showAudioBar);
                                  },
                                  tooltip: 'استماع',
                                ),
                                // Clear highlight button (only shown when there's a highlight)
                                if (highlighted != null)
                                  IconButton(
                                    icon: const Icon(Icons.highlight_off, color: Color(0xFFD4A017), size: 22),
                                    onPressed: () {
                                      ref.read(highlightedAyahProvider.notifier).clearHighlight();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تم مسح العلامة', style: GoogleFonts.cairo()),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor: const Color(0xFF2C1810),
                                        ),
                                      );
                                    },
                                    tooltip: 'مسح العلامة',
                                  ),
                                Builder(
                                  builder: (_) {
                                    final p = pages[_currentPage];
                                    final bookmarks = ref.watch(bookmarkProvider);
                                    final isSaved = p != null &&
                                        p.sections.isNotEmpty &&
                                        bookmarks.any((b) =>
                                            b.surahNumber ==
                                                p.sections.first.surahNumber &&
                                            b.ayahNumber ==
                                                p.sections.first.ayahs.first
                                                    .ayahNumber);
                                    return IconButton(
                                      icon: Icon(
                                        isSaved
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: isSaved
                                            ? const Color(0xFFD4A017)
                                            : Colors.white,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        if (p != null && p.sections.isNotEmpty) {
                                          ref
                                              .read(bookmarkProvider.notifier)
                                              .toggleBookmark(
                                                p.sections.first.surahNumber,
                                                p.sections.first.ayahs.first
                                                    .ayahNumber,
                                              );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  isSaved
                                                      ? 'تم مسح العلامة'
                                                      : 'تم حفظ العلامة',
                                                  style: GoogleFonts.cairo()),
                                              duration:
                                                  const Duration(seconds: 1),
                                              backgroundColor:
                                                  const Color(0xFF2C1810),
                                            ),
                                          );
                                        }
                                      },
                                      tooltip: isSaved
                                          ? 'مسح العلامة'
                                          : 'علامة مرجعية',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _controlsFade,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1810).withValues(alpha: 0.92),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Page slider
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      '٦٠٤',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Expanded(
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: SliderTheme(
                                          data: SliderThemeData(
                                            activeTrackColor: const Color(0xFFD4A017),
                                            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                                            thumbColor: const Color(0xFFD4A017),
                                            overlayColor: const Color(0xFFD4A017).withValues(alpha: 0.15),
                                            trackHeight: 3,
                                            thumbShape: const RoundSliderThumbShape(
                                              enabledThumbRadius: 7,
                                            ),
                                          ),
                                          child: Slider(
                                            value: _currentPage.toDouble(),
                                            min: 1,
                                            max: 604,
                                            onChanged: (v) => _goToPage(v.round()),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '١',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quick actions
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildQuickAction(Icons.first_page, 'البداية', () => _goToPage(1)),
                                    _buildQuickAction(Icons.format_list_numbered, 'الفهرس', () => Navigator.of(context).pop()),
                                    _buildQuickAction(Icons.search, 'بحث', _showSearch),
                                    _buildQuickAction(Icons.last_page, 'النهاية', () => _goToPage(604)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // ===== AUDIO BAR =====
                // Only visible when controls are revealed (tap on page) or when
                // the user manually pinned the bar via the headset button.
                // Auto-hides with the controls so it doesn't cover the page.
                if (_showControls || _showAudioBar)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: QuranAudioBar(
                      surahNumber: pages[_currentPage]?.sections.isNotEmpty == true
                          ? pages[_currentPage]!.sections.last.surahNumber
                          : 1,
                      surahName: _currentSurahName,
                    ),
                  ),

                // ===== PAGE INDICATOR (always visible at bottom center) =====
                if (!_showControls && !_showAudioBar)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1810).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          '${_toArabicNumber(_currentPage)} / ٦٠٤',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => Container(
            color: const Color(0xFFFFF8EC),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFFB8860B),
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'جارٍ تحميل المصحف...',
                    style: GoogleFonts.cairo(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'حدث خطأ في تحميل المصحف',
                  style: GoogleFonts.cairo(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => ref.invalidate(pageIndexProvider),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
