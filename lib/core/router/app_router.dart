import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';
import '../../features/azkar/presentation/azkar_categories_screen.dart';
import '../../features/azkar/presentation/azkar_detail_screen.dart';
import '../../features/duas/presentation/duas_categories_screen.dart';
import '../../features/duas/presentation/dua_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/prayer_times/presentation/prayer_times_screen.dart';
import '../../features/qibla/presentation/qibla_screen.dart';
import '../../features/quran/presentation/surah_list_screen.dart';
import '../../features/quran/presentation/surah_reader_screen.dart';
import '../../features/sebha/presentation/sebha_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Creates the app router configuration with all routes.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash screen (no bottom nav)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/azkar',
            name: 'azkar',
            builder: (context, state) => const AzkarCategoriesScreen(),
            routes: [
              GoRoute(
                path: ':categoryId',
                name: 'azkar-category',
                builder: (context, state) {
                  final categoryId = state.pathParameters['categoryId'] ?? '';
                  return AzkarDetailScreen(categoryId: categoryId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/duas',
            name: 'duas',
            builder: (context, state) => const DuasCategoriesScreen(),
            routes: [
              GoRoute(
                path: ':categoryId',
                name: 'duas-category',
                builder: (context, state) {
                  final categoryId = state.pathParameters['categoryId'] ?? '';
                  return DuaDetailScreen(categoryId: categoryId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/quran',
            name: 'quran',
            builder: (context, state) => const SurahListScreen(),
            routes: [
              GoRoute(
                path: ':surahNumber',
                name: 'quran-surah',
                builder: (context, state) {
                  final surahNumber =
                      int.tryParse(state.pathParameters['surahNumber'] ?? '') ?? 1;
                  return SurahReaderScreen(surahNumber: surahNumber);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/sebha',
            name: 'sebha',
            builder: (context, state) => const SebhaScreen(),
          ),
          GoRoute(
            path: '/prayer-times',
            name: 'prayer-times',
            builder: (context, state) => const PrayerTimesScreen(),
          ),
          GoRoute(
            path: '/qibla',
            name: 'qibla',
            builder: (context, state) => const QiblaScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Main shell screen with bottom navigation bar.
/// Wraps the 4 main tabs: Home, Azkar, Quran, Settings.
class MainShellScreen extends StatelessWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/azkar') ||
        location.startsWith('/duas') ||
        location.startsWith('/sebha') ||
        location.startsWith('/prayer-times') ||
        location.startsWith('/qibla')) return 1;
    if (location.startsWith('/quran')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/azkar');
      case 2:
        context.go('/quran');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(context, index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.homeTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories),
              label: AppStrings.azkarTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: AppStrings.quranTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: AppStrings.settingsTab,
            ),
          ],
        ),
      ),
    );
  }
}
