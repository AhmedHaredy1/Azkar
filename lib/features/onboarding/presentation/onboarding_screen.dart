import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'providers/onboarding_provider.dart';
import 'widgets/dot_indicator.dart';
import 'widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navigate to home after completing onboarding.
  Future<void> _completeOnboarding() async {
    final notifier = ref.read(onboardingProvider.notifier);

    // Request permissions before completing
    await notifier.requestLocationPermission();
    await notifier.requestNotificationPermission();

    // Mark onboarding as done
    await notifier.completeOnboarding();

    if (mounted) {
      context.go('/home');
    }
  }

  /// Skip onboarding — go directly to home.
  Future<void> _skipOnboarding() async {
    final notifier = ref.read(onboardingProvider.notifier);
    await notifier.completeOnboarding();

    if (mounted) {
      context.go('/home');
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = state.currentPage == OnboardingNotifier.totalPages - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar with skip button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (!isLastPage)
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: Text(
                          AppStrings.skip,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 48),
                  ],
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    ref.read(onboardingProvider.notifier).goToPage(index);
                  },
                  children: const [
                    // Page 1: Azkar
                    OnboardingPage(
                      icon: Icons.auto_stories_rounded,
                      title: AppStrings.onboardingTitle1,
                      description: AppStrings.onboardingDesc1,
                    ),
                    // Page 2: Prayer Times & Qibla
                    OnboardingPage(
                      icon: Icons.mosque_rounded,
                      title: AppStrings.onboardingTitle2,
                      description: AppStrings.onboardingDesc2,
                    ),
                    // Page 3: Quran
                    OnboardingPage(
                      icon: Icons.menu_book_rounded,
                      title: AppStrings.onboardingTitle3,
                      description: AppStrings.onboardingDesc3,
                    ),
                  ],
                ),
              ),

              // Bottom section: dot indicator + button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  children: [
                    // Dot indicator
                    DotIndicator(
                      itemCount: OnboardingNotifier.totalPages,
                      currentIndex: state.currentPage,
                    ),

                    const SizedBox(height: 32),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLastPage
                            ? _completeOnboarding
                            : () => _goToPage(state.currentPage + 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isLastPage ? AppStrings.getStarted : AppStrings.next,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
