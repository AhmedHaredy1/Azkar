import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';
import '../widgets/global_mini_player.dart';
import '../../features/azkar/presentation/azkar_categories_screen.dart';
import '../../features/azkar/presentation/azkar_completion_screen.dart';
import '../../features/azkar/presentation/azkar_detail_screen.dart';
import '../../features/azkar/presentation/azkar_favorites_screen.dart';
import '../../features/duas/presentation/duas_categories_screen.dart';
import '../../features/duas/presentation/duas_favorites_screen.dart';
import '../../features/duas/presentation/dua_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/prayer_times/presentation/prayer_times_screen.dart';
import '../../features/qibla/presentation/qibla_screen.dart';
import '../../features/quran/presentation/surah_list_screen.dart';
import '../../features/quran/presentation/surah_reader_screen.dart';
import '../../features/sebha/presentation/sebha_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/quran_listen/presentation/quran_listen_screen.dart';
import '../../features/live_radio/presentation/live_radio_screen.dart';
import '../../features/hajj_umrah/presentation/hajj_umrah_screen.dart';

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

      // Onboarding screen (first launch only, no bottom nav)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
                path: 'favorites',
                name: 'azkar-favorites',
                builder: (context, state) => const AzkarFavoritesScreen(),
              ),
              GoRoute(
                path: ':categoryId',
                name: 'azkar-category',
                builder: (context, state) {
                  final categoryId = state.pathParameters['categoryId'] ?? '';
                  return AzkarDetailScreen(categoryId: categoryId);
                },
                routes: [
                  GoRoute(
                    path: 'complete',
                    name: 'azkar-complete',
                    builder: (context, state) {
                      final categoryName =
                          state.uri.queryParameters['name'] ?? 'الأذكار';
                      return AzkarCompletionScreen(categoryName: categoryName);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/duas',
            name: 'duas',
            builder: (context, state) => const DuasCategoriesScreen(),
            routes: [
              GoRoute(
                path: 'favorites',
                name: 'duas-favorites',
                builder: (context, state) => const DuasFavoritesScreen(),
              ),
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
            path: '/quran-listen',
            name: 'quran-listen',
            builder: (context, state) => const QuranListenScreen(),
          ),
          GoRoute(
            path: '/live-radio',
            name: 'live-radio',
            builder: (context, state) => const LiveRadioScreen(),
          ),
          GoRoute(
            path: '/hajj-umrah',
            name: 'hajj-umrah',
            builder: (context, state) => const HajjUmrahScreen(),
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
class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/azkar') ||
        location.startsWith('/duas') ||
        location.startsWith('/sebha') ||
        location.startsWith('/prayer-times') ||
        location.startsWith('/qibla') ||
        location.startsWith('/quran-listen') ||
        location.startsWith('/live-radio') ||
        location.startsWith('/hajj-umrah')) {
      return 1;
    }
    if (location.startsWith('/quran')) {
      return 2;
    }
    if (location.startsWith('/settings')) {
      return 3;
    }
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

  /// Routes that render their own in-screen audio player UI — hide the
  /// global mini player on these so the user doesn't see two player bars.
  ///
  /// Note: live radio and the surah list have no built-in player, so the
  /// global mini player MUST stay visible there. /quran-listen has its own
  /// bottom-sheet player; /quran reaches Mushaf via Navigator.push and
  /// Mushaf has its own QuranAudioBar overlay.
  bool _hasInScreenPlayer(String path) {
    return path.startsWith('/quran-listen') ||
        path.startsWith('/quran');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final path = GoRouterState.of(context).uri.path;
    final showMiniPlayer = !_hasInScreenPlayer(path);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(child: child),
            if (showMiniPlayer) const GlobalMiniPlayer(),
          ],
        ),
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
