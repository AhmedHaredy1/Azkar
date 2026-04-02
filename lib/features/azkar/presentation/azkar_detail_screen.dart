import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/app_colors.dart';
import 'providers/azkar_provider.dart';
import 'widgets/dhikr_card.dart';

class AzkarDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const AzkarDetailScreen({super.key, required this.categoryId});

  @override
  ConsumerState<AzkarDetailScreen> createState() => _AzkarDetailScreenState();
}

class _AzkarDetailScreenState extends ConsumerState<AzkarDetailScreen> {
  bool _initialized = false;

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(azkarCategoryProvider(widget.categoryId));
    final progress = ref.watch(azkarProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: categoryAsync.when(
          data: (cat) => Text(
            cat?.nameAr ?? 'الأذكار',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          loading: () => const Text(''),
          error: (_, __) => const Text('خطأ'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      body: categoryAsync.when(
        data: (category) {
          if (category == null || category.azkarList.isEmpty) {
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

          final azkarList = category.azkarList;

          // Initialize progress on first build
          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(azkarProgressProvider.notifier).initialize(azkarList);
            });
            _initialized = true;
          }

          if (progress.isCompleted) {
            return _buildCompletedView();
          }

          final currentDhikr = azkarList[progress.currentIndex];

          return GestureDetector(
            onTap: () async {
              // Vibrate on tap
              if (await Vibration.hasVibrator()) {
                Vibration.vibrate(duration: 30);
              }
              ref.read(azkarProgressProvider.notifier).decrementAndAdvance(azkarList);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Progress indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_toArabicNumber(progress.currentIndex + 1)} من ${_toArabicNumber(azkarList.length)}',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                              'المتبقي: ${_toArabicNumber(progress.remainingCount)}',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (progress.currentIndex + 1) / azkarList.length,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          color: AppColors.primary,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Dhikr text
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: DhikrCard(
                            text: currentDhikr.textAr,
                            source: currentDhikr.source,
                            note: currentDhikr.note,
                          ),
                        ),
                      ),
                    ),
                    // Counter circle
                    Container(
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
                          _toArabicNumber(progress.remainingCount),
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                'حدث خطأ',
                style: GoogleFonts.cairo(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 60,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'أحسنت! أتممت الأذكار',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تقبّل الله منك',
            style: GoogleFonts.amiri(
              fontSize: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _initialized = false);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة'),
          ),
        ],
      ),
    );
  }
}
