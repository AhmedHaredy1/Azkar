import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../domain/models/azkar_category.dart';
import 'azkar_completion_screen.dart';
import 'providers/azkar_provider.dart';
import 'widgets/dhikr_card.dart';

class AzkarDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const AzkarDetailScreen({super.key, required this.categoryId});

  @override
  ConsumerState<AzkarDetailScreen> createState() => _AzkarDetailScreenState();
}

class _AzkarDetailScreenState extends ConsumerState<AzkarDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  bool _navigatedToCompletion = false;

  // Animation for counter pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap(List<Dhikr> azkarList) async {
    final progress = ref.read(azkarProgressProvider);
    if (progress.isCompleted) return;

    // Vibration feedback
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 30);
    }

    // Pulse animation on counter
    _pulseController.forward().then((_) => _pulseController.reverse());

    // Decrement counter
    ref.read(azkarProgressProvider.notifier).decrementAndAdvance(azkarList);

    // Check if just completed all azkar
    final newProgress = ref.read(azkarProgressProvider);
    if (newProgress.isCompleted && !_navigatedToCompletion) {
      _navigatedToCompletion = true;
      // Short delay for the last vibration to be felt
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        // Vibrate longer for completion
        final canVibrate = await Vibration.hasVibrator();
        if (canVibrate == true) {
          Vibration.vibrate(duration: 100);
        }
        _navigateToCompletion();
      }
    }
  }

  void _navigateToCompletion() {
    final categoryAsync = ref.read(azkarCategoryProvider(widget.categoryId));
    final categoryName = categoryAsync.valueOrNull?.nameAr ?? 'الأذكار';

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AzkarCompletionScreen(categoryName: categoryName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(azkarCategoryProvider(widget.categoryId));
    final progress = ref.watch(azkarProgressProvider);
    final favorites = ref.watch(azkarFavoritesProvider);

    return Scaffold(
      appBar: _buildAppBar(categoryAsync, progress),
      body: categoryAsync.when(
        data: (category) {
          if (category == null || category.azkarList.isEmpty) {
            return _buildEmptyState();
          }

          final azkarList = category.azkarList;

          // Initialize progress on first build
          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(azkarProgressProvider.notifier).initialize(azkarList);
            });
            _initialized = true;
          }

          if (progress.isCompleted && !_navigatedToCompletion) {
            // Delay navigation slightly so the screen doesn't flash
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_navigatedToCompletion && _initialized) {
                _navigatedToCompletion = true;
                _navigateToCompletion();
              }
            });
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (progress.currentIndex >= azkarList.length) {
            return const SizedBox.shrink();
          }

          final currentDhikr = azkarList[progress.currentIndex];
          final dhikrKey = '${category.id}:${currentDhikr.id}';
          final isFav = favorites.contains(dhikrKey);

          return GestureDetector(
            onTap: () => _onTap(azkarList),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Progress row
                    _buildProgressRow(progress, azkarList.length),

                    const SizedBox(height: 8),

                    // Linear progress bar
                    _buildProgressBar(progress, azkarList.length),

                    const SizedBox(height: 20),

                    // Dhikr card with favorite button
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.15, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _buildDhikrContent(
                          key: ValueKey(progress.currentIndex),
                          dhikr: currentDhikr,
                          isFavorite: isFav,
                          dhikrKey: dhikrKey,
                        ),
                      ),
                    ),

                    // Counter circle at bottom
                    _buildCounterCircle(progress),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _buildErrorState(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AsyncValue<AzkarCategory?> categoryAsync,
    AzkarProgressState progress,
  ) {
    return AppBar(
      title: categoryAsync.when(
        data: (cat) => Column(
          children: [
            Text(
              cat?.nameAr ?? 'الأذكار',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (cat != null && !progress.isCompleted)
              Text(
                '${ArabicNumberUtils.toEasternArabic(progress.completedCount)} من ${ArabicNumberUtils.toEasternArabic(cat.azkarList.length)} مكتمل',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        loading: () => const Text(''),
        error: (_, __) => const Text('خطأ'),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      centerTitle: true,
      // Linear progress in the AppBar bottom
      bottom: categoryAsync.when(
        data: (cat) {
          if (cat == null || progress.isCompleted) return null;
          final total = cat.azkarList.length;
          final progressValue = total > 0
              ? progress.completedCount / total
              : 0.0;
          return PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: AppColors.primaryDark,
              color: AppColors.secondary,
              minHeight: 3,
            ),
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildProgressRow(AzkarProgressState progress, int totalCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current position: "٣ من ١٢"
          Text(
            '${ArabicNumberUtils.toEasternArabic(progress.currentIndex + 1)} من ${ArabicNumberUtils.toEasternArabic(totalCount)}',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Remaining count badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'المتبقي: ${ArabicNumberUtils.toEasternArabic(progress.remainingCount)}',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AzkarProgressState progress, int totalCount) {
    final progressValue = totalCount > 0
        ? (progress.currentIndex) / totalCount
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progressValue,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          color: AppColors.primary,
          minHeight: 4,
        ),
      ),
    );
  }

  Widget _buildDhikrContent({
    required Key key,
    required Dhikr dhikr,
    required bool isFavorite,
    required String dhikrKey,
  }) {
    return KeyedSubtree(
      key: key,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Favorite button
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 24),
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(azkarFavoritesProvider.notifier)
                          .toggleFavorite(dhikrKey);
                      final newFav = !isFavorite;
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newFav
                                ? 'تمت الإضافة إلى المفضلة'
                                : 'تمت الإزالة من المفضلة',
                            style: GoogleFonts.cairo(),
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(isFavorite),
                        size: 28,
                        color: isFavorite
                            ? Colors.red.shade400
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              DhikrCard(
                text: dhikr.textAr,
                source: dhikr.source,
                note: dhikr.note,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterCircle(AzkarProgressState progress) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 32),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            ArabicNumberUtils.toEasternArabic(progress.remainingCount),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'لا توجد أذكار في هذا القسم',
        style: GoogleFonts.cairo(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style:
                GoogleFonts.cairo(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
