import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../azkar/domain/models/azkar_category.dart';
import '../../azkar/presentation/providers/azkar_provider.dart';

/// Streamlined post-Fard guided dhikr counter (أذكار دبر الصلاة).
///
/// Reuses the `after_prayer` category data from azkar.json but presents it
/// in a tap-to-count flow optimized for speed: one large dhikr card, a big
/// tap-anywhere counter, vibration feedback, auto-advance when count is
/// reached, and a final celebration when all 13 adhkar are complete.
class PostPrayerDhikrScreen extends ConsumerStatefulWidget {
  /// Optional prayer name (Fajr/Dhuhr/Asr/Maghrib/Isha) — when provided,
  /// shown in the app bar to anchor the user to which prayer they just made.
  final String? prayerName;

  const PostPrayerDhikrScreen({super.key, this.prayerName});

  @override
  ConsumerState<PostPrayerDhikrScreen> createState() =>
      _PostPrayerDhikrScreenState();
}

class _PostPrayerDhikrScreenState extends ConsumerState<PostPrayerDhikrScreen> {
  int _currentIndex = 0;
  int _remaining = 0;
  bool _initialized = false;
  bool? _hasVibrator;

  Future<void> _initVibrator() async {
    _hasVibrator = await Vibration.hasVibrator();
  }

  @override
  void initState() {
    super.initState();
    _initVibrator();
  }

  void _ensureInitialized(List<Dhikr> azkar) {
    if (_initialized) return;
    _initialized = true;
    _remaining = azkar.isNotEmpty ? azkar.first.repetitions : 0;
  }

  Future<void> _tap(List<Dhikr> azkar) async {
    if (_currentIndex >= azkar.length) return;

    final next = _remaining - 1;

    if (_hasVibrator == true) {
      // Short pulse — light haptic so the user can feel each count.
      Vibration.vibrate(duration: 30);
    }
    HapticFeedback.selectionClick();

    if (next > 0) {
      setState(() => _remaining = next);
      return;
    }

    // Reached zero on the current dhikr — advance.
    if (_currentIndex + 1 >= azkar.length) {
      // All done — strong haptic and show completion.
      if (_hasVibrator == true) {
        Vibration.vibrate(duration: 300);
      }
      setState(() {
        _remaining = 0;
        _currentIndex = azkar.length;
      });
      return;
    }

    setState(() {
      _currentIndex += 1;
      _remaining = azkar[_currentIndex].repetitions;
    });
  }

  void _restart(List<Dhikr> azkar) {
    setState(() {
      _currentIndex = 0;
      _remaining = azkar.isNotEmpty ? azkar.first.repetitions : 0;
    });
  }

  void _skip(List<Dhikr> azkar) {
    if (_currentIndex + 1 >= azkar.length) {
      setState(() {
        _currentIndex = azkar.length;
        _remaining = 0;
      });
      return;
    }
    setState(() {
      _currentIndex += 1;
      _remaining = azkar[_currentIndex].repetitions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(azkarCategoryProvider('after_prayer'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.prayerName != null
              ? 'أذكار بعد صلاة ${_arabicPrayerName(widget.prayerName!)}'
              : 'أذكار دبر الصلاة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: categoryAsync.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => const AppErrorView(
          message: 'تعذّر تحميل أذكار دبر الصلاة',
        ),
        data: (category) {
          if (category == null || category.azkarList.isEmpty) {
            return Center(
              child: Text(
                'لا توجد أذكار متاحة',
                style: GoogleFonts.cairo(),
              ),
            );
          }
          _ensureInitialized(category.azkarList);
          final azkar = category.azkarList;
          final completed = _currentIndex >= azkar.length;
          final progress = completed
              ? 1.0
              : _currentIndex / azkar.length;

          if (completed) {
            return _CompletionView(
              prayerName: widget.prayerName,
              onRestart: () => _restart(azkar),
              onClose: () => context.pop(),
            );
          }

          final current = azkar[_currentIndex];
          return Column(
            children: [
              // Progress strip
              LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${azkar.length}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (current.note.isNotEmpty)
                      Flexible(
                        child: Text(
                          current.note,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Dhikr text card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F2A1F)
                          : const Color(0xFFFAF8F0),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          current.textAr,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: 22,
                            height: 1.9,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (current.source.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            current.source,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Tap-to-count surface
              GestureDetector(
                onTap: () => _tap(azkar),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  margin: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_remaining',
                        style: GoogleFonts.cairo(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اضغط للعد',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer controls
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _restart(azkar),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _skip(azkar),
                        icon: const Icon(Icons.skip_next),
                        label: const Text('تخطٍّ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _arabicPrayerName(String englishName) {
    switch (englishName) {
      case 'Fajr':
        return 'الفجر';
      case 'Dhuhr':
        return 'الظهر';
      case 'Asr':
        return 'العصر';
      case 'Maghrib':
        return 'المغرب';
      case 'Isha':
        return 'العشاء';
      default:
        return '';
    }
  }
}

class _CompletionView extends StatelessWidget {
  final String? prayerName;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _CompletionView({
    required this.prayerName,
    required this.onRestart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'تقبّل الله طاعتك',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'أتممتَ أذكار دبر الصلاة',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.home_outlined),
              label: const Text('العودة'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة الأذكار'),
            ),
          ],
        ),
      ),
    );
  }
}
