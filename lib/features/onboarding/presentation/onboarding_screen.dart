import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/tokens.dart';
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

  Future<void> _completeOnboarding() async {
    final notifier = ref.read(onboardingProvider.notifier);
    await notifier.requestLocationPermission();
    await notifier.requestNotificationPermission();
    await notifier.completeOnboarding();
    if (mounted) context.go('/home');
  }

  Future<void> _skipOnboarding() async {
    final notifier = ref.read(onboardingProvider.notifier);
    await notifier.completeOnboarding();
    if (mounted) context.go('/home');
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
    final total = OnboardingNotifier.totalPages;
    final isLastPage = state.currentPage == total - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    ref.read(onboardingProvider.notifier).goToPage(index);
                  },
                  children: [
                    OnboardingPage(
                      icon: Icons.auto_stories_rounded,
                      title: AppStrings.onboardingTitle1,
                      description: AppStrings.onboardingDesc1,
                      stepIndex: 0,
                      totalSteps: total,
                    ),
                    OnboardingPage(
                      icon: Icons.mosque_rounded,
                      title: AppStrings.onboardingTitle2,
                      description: AppStrings.onboardingDesc2,
                      stepIndex: 1,
                      totalSteps: total,
                    ),
                    OnboardingPage(
                      icon: Icons.menu_book_rounded,
                      title: AppStrings.onboardingTitle3,
                      description: AppStrings.onboardingDesc3,
                      stepIndex: 2,
                      totalSteps: total,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl + 2,
                  0,
                  AppSpacing.xl + 2,
                  AppSpacing.xl + AppSpacing.md,
                ),
                child: Column(
                  children: [
                    DotIndicator(
                      itemCount: total,
                      currentIndex: state.currentPage,
                    ),
                    const SizedBox(height: AppSpacing.lg + 4),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: isLastPage
                            ? _completeOnboarding
                            : () => _goToPage(state.currentPage + 1),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(
                          isLastPage ? AppStrings.getStarted : AppStrings.next,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: isLastPage ? null : _skipOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.ink3,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppStrings.skip,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.ink3,
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
