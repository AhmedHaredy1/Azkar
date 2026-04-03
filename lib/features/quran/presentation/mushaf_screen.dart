import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import 'providers/quran_provider.dart';
import 'widgets/mushaf_page_widget.dart';
import 'widgets/quran_search_dialog.dart';

class MushafScreen extends ConsumerStatefulWidget {
  final int initialPage;

  const MushafScreen({super.key, this.initialPage = 0});

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  late PageController _pageController;
  int _currentPage = 1;
  bool _showOverlay = true;

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  @override
  void initState() {
    super.initState();
    // Use initialPage if provided, otherwise use last read page
    final startPage =
        widget.initialPage > 0 ? widget.initialPage : 1;
    _currentPage = startPage;
    _pageController = PageController(initialPage: startPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 1 || page > 604) return;
    _pageController.jumpToPage(page - 1);
    setState(() => _currentPage = page);
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuranSearchDialog(
        onGoToPage: _goToPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(pageIndexProvider);

    // Resolve last read page on first build if no initialPage specified
    if (widget.initialPage <= 0) {
      final lastRead = ref.watch(lastReadPageProvider);
      if (_currentPage == 1 && lastRead > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToPage(lastRead);
        });
      }
    }

    return Scaffold(
      body: pagesAsync.when(
        data: (pages) {
          if (pages.isEmpty) {
            return Center(
              child: Text(
                'لا توجد بيانات',
                style: GoogleFonts.cairo(fontSize: 16),
              ),
            );
          }

          return GestureDetector(
            onTap: () => setState(() => _showOverlay = !_showOverlay),
            child: Stack(
              children: [
                // Page view - RIGHT to LEFT for Arabic
                PageView.builder(
                  controller: _pageController,
                  reverse: true,
                  itemCount: 604,
                  onPageChanged: (index) {
                    final page = index + 1;
                    setState(() => _currentPage = page);
                    ref.read(lastReadPageProvider.notifier).setPage(page);
                  },
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;
                    final quranPage = pages[pageNum];
                    if (quranPage == null) {
                      return Container(
                        color: const Color(0xFFFAF6EF),
                        child: Center(
                          child: Text(
                            'صفحة ${_toArabicNumber(pageNum)}',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }
                    return MushafPageWidget(page: quranPage);
                  },
                ),

                // Top overlay
                if (_showOverlay)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.95),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              Text(
                                'صفحة ${_toArabicNumber(_currentPage)}',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.search,
                                    color: Colors.white),
                                onPressed: _showSearch,
                              ),
                              IconButton(
                                icon: const Icon(Icons.list,
                                    color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                                tooltip: 'فهرس السور',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bottom page slider
                if (_showOverlay)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.9),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Page slider
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: AppColors.secondary,
                                    inactiveTrackColor:
                                        Colors.white.withValues(alpha: 0.3),
                                    thumbColor: AppColors.secondary,
                                    overlayColor:
                                        AppColors.secondary.withValues(alpha: 0.2),
                                    trackHeight: 3,
                                  ),
                                  child: Slider(
                                    value: _currentPage.toDouble(),
                                    min: 1,
                                    max: 604,
                                    onChanged: (v) {
                                      _goToPage(v.round());
                                    },
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '٦٠٤',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'صفحة ${_toArabicNumber(_currentPage)} من ٦٠٤',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '١',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => Container(
          color: const Color(0xFFFAF6EF),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل المصحف',
                style: GoogleFonts.cairo(fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(pageIndexProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
