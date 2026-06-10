import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../../core/widgets/ornaments.dart';
import '../../azkar_streaks/presentation/providers/azkar_streaks_provider.dart';
import '../domain/models/azkar_category.dart';
import 'providers/azkar_provider.dart';
import 'widgets/azkar_category_card.dart';

class AzkarCategoriesScreen extends ConsumerStatefulWidget {
  const AzkarCategoriesScreen({super.key});

  @override
  ConsumerState<AzkarCategoriesScreen> createState() =>
      _AzkarCategoriesScreenState();
}

class _AzkarCategoriesScreenState extends ConsumerState<AzkarCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter categories by name OR by any contained dhikr text/source.
  /// Empty query returns the original list.
  List<AzkarCategory> _filter(List<AzkarCategory> all) {
    final q = _query.trim();
    if (q.isEmpty) return all;
    final needle = _normalize(q);
    return all.where((cat) {
      if (_normalize(cat.nameAr).contains(needle)) return true;
      for (final d in cat.azkarList) {
        if (_normalize(d.textAr).contains(needle)) return true;
        if (d.source.isNotEmpty && _normalize(d.source).contains(needle)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  /// Strip Arabic diacritics + tatweel and normalize alef/yaa/taa-marbuta so
  /// "الله" matches "اللّه" and "اذكار" matches "أذكار".
  String _normalize(String s) {
    final stripped = s.replaceAll(RegExp('[\u064B-\u0652\u0670\u0640]'), '');
    return stripped
        .replaceAll(RegExp('[إأآا]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(azkarCategoriesProvider);
    final favorites = ref.watch(azkarFavoritesProvider);
    final hasFavorites = favorites.isNotEmpty;
    final streaks = ref.watch(azkarStreaksProvider);
    final isSearching = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد أذكار',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.ink3,
                  ),
                ),
              );
            }
            final visible = _filter(categories);
            return CustomScrollView(
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
                          hasFavorites: hasFavorites,
                          onFavorites: () => context.push('/azkar/favorites'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SearchField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isSearching) ...[
                          _FeaturedStreakCard(streaks: streaks),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        _SectionLabel(
                          text: isSearching ? 'نتائج البحث' : 'الفئات',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xl,
                      ),
                      child: Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: AppColors.ink3,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final category = visible[index];
                      return AzkarCategoryCard(
                        category: category,
                        index: index,
                        onTap: () => context.push('/azkar/${category.id}'),
                      );
                    },
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'حدث خطأ في تحميل الأذكار',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => ref.invalidate(azkarCategoriesProvider),
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
}

class _TitleRow extends StatelessWidget {
  final bool hasFavorites;
  final VoidCallback onFavorites;

  const _TitleRow({required this.hasFavorites, required this.onFavorites});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'الأذكار',
          style: GoogleFonts.cairo(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        GestureDetector(
          onTap: onFavorites,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Icon(
              hasFavorites ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: hasFavorites ? AppColors.secondary : AppColors.ink2,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 16, color: AppColors.ink3),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.primary,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                border: InputBorder.none,
                hintText: 'ابحث في الأذكار…',
                hintStyle: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.ink3,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.ink3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedStreakCard extends StatelessWidget {
  final AzkarStreaksState streaks;

  const _FeaturedStreakCard({required this.streaks});

  @override
  Widget build(BuildContext context) {
    final streak = streaks.currentStreak;
    final today = DateTime.now();
    final didMorning = streaks.didMorning(today);
    final didEvening = streaks.didEvening(today);

    final String label;
    final double progress;
    if (!didMorning) {
      label = 'أكمل أذكار الصباح اليوم';
      progress = 0;
    } else if (!didEvening) {
      label = 'أكمل أذكار المساء اليوم';
      progress = 0.5;
    } else {
      label = 'أكملت أذكار اليوم — بارك الله فيك';
      progress = 1;
    }

    final subtitle = streak > 0
        ? 'سلسلة ${ArabicNumberUtils.toEasternArabic(streak)} ${streak == 1 ? 'يوم' : 'يوماً'}'
        : 'ابدأ سلسلتك اليوم';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFF8F0DC), Color(0xFFF2ECDC)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            alignment: Alignment.center,
            child: StarMark(size: 20, color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.ink2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Stack(
                    children: [
                      Container(
                        height: 4,
                        color: const Color(0x2EB8892A),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 4,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.ink3,
        letterSpacing: 0.8,
      ),
    );
  }
}
