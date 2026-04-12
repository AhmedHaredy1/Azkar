import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  /// Check isFirstLaunch flag and navigate accordingly.
  void _navigateToNextScreen() {
    final storage = StorageService.instance;
    final isFirstLaunch =
        storage.getSetting<bool>('isFirstLaunch', defaultValue: true) ?? true;

    if (isFirstLaunch) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryLight,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Islamic decoration - crescent icon
                const Icon(
                  Icons.mosque_outlined,
                  size: 80,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 24),
                // Decorative line
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 24),
                // App name
                Text(
                  'حصن المسلم',
                  style: GoogleFonts.amiri(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أذكار وأدعية من الكتاب والسنة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                // Decorative line
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 16),
                // Star decorations
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 12, color: AppColors.secondary.withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Icon(Icons.star, size: 12, color: AppColors.secondary.withValues(alpha: 0.6)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
