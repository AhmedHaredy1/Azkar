import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/models/quran_page.dart';
import '../../domain/models/surah.dart';
import '../providers/quran_provider.dart';

class QuranSearchDialog extends ConsumerStatefulWidget {
  final void Function(int page) onGoToPage;

  const QuranSearchDialog({super.key, required this.onGoToPage});

  @override
  ConsumerState<QuranSearchDialog> createState() => _QuranSearchDialogState();
}

class _QuranSearchDialogState extends ConsumerState<QuranSearchDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pageController = TextEditingController();
  final _searchController = TextEditingController();
  int? _selectedSurah;
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await ref
        .read(quranLocalSourceProvider)
        .searchAyahs(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF6EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'البحث في القرآن',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'رقم الصفحة'),
              Tab(text: 'السورة'),
              Tab(text: 'بحث نصي'),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Page number tab
                _buildPageTab(),
                // Surah tab
                surahsAsync.when(
                  data: (surahs) => _buildSurahTab(surahs),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (_, _) => const Center(child: Text('خطأ')),
                ),
                // Text search tab
                _buildSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'أدخل رقم الصفحة (١ - ٦٠٤)',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '١',
              hintStyle: GoogleFonts.cairo(
                fontSize: 24,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final page = int.tryParse(_pageController.text);
                if (page != null && page >= 1 && page <= 604) {
                  Navigator.of(context).pop();
                  widget.onGoToPage(page);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'انتقل',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahTab(List<Surah> surahs) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Surah dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedSurah,
                hint: Text(
                  'اختر السورة',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary),
                ),
                isExpanded: true,
                items: surahs.map((s) {
                  return DropdownMenuItem(
                    value: s.number,
                    child: Text(
                      '${_toArabicNumber(s.number)}. ${s.nameAr}',
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(fontSize: 18),
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedSurah = v),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedSurah == null
                  ? null
                  : () async {
                      final page = await ref
                          .read(quranLocalSourceProvider)
                          .getPageForSurah(_selectedSurah!);
                      if (mounted) {
                        Navigator.of(context).pop();
                        widget.onGoToPage(page);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'انتقل للسورة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Quick surah list
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView.builder(
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                final s = surahs[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      _toArabicNumber(s.number),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    s.nameAr,
                    style: GoogleFonts.amiri(fontSize: 16),
                  ),
                  subtitle: Text(
                    '${s.nameEn} - ${_toArabicNumber(s.ayahCount)} آية',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  onTap: () async {
                    final nav = Navigator.of(context);
                    final goToPage = widget.onGoToPage;
                    final page = await ref
                        .read(quranLocalSourceProvider)
                        .getPageForSurah(s.number);
                    if (mounted) {
                      nav.pop();
                      goToPage(page);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'ابحث في القرآن...',
              hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onSubmitted: _performSearch,
            onChanged: (v) {
              if (v.length >= 3) _performSearch(v);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'لا توجد نتائج',
                style: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final r = _searchResults[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    color: const Color(0xFFFAF8F3),
                    child: ListTile(
                      title: Text(
                        r.text.length > 80
                            ? '${r.text.substring(0, 80)}...'
                            : r.text,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          height: 1.6,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${r.surahNameAr} - آية ${_toArabicNumber(r.ayahNumber)} | صفحة ${_toArabicNumber(r.page)}',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onGoToPage(r.page);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
