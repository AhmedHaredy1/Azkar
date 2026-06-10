import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/storage_keys.dart';
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
import '../services/storage_service.dart';
import '../../features/quran_listen/presentation/quran_listen_screen.dart';
import '../../features/live_radio/presentation/live_radio_screen.dart';
import '../../features/hajj_umrah/presentation/hajj_umrah_screen.dart';
import '../../features/notifications/presentation/notification_status_screen.dart';
import '../../features/post_prayer_dhikr/presentation/post_prayer_dhikr_screen.dart';
import '../../features/ramadan/presentation/ramadan_screen.dart';
import '../../features/khatma/presentation/khatma_screen.dart';
import '../../features/asma_allah/presentation/asma_allah_screen.dart';
import '../../features/hadith_of_day/presentation/hadith_of_day_screen.dart';
import '../../features/wudu/presentation/wudu_screen.dart';
import '../../features/islamic_calendar/presentation/islamic_calendar_screen.dart';
import '../../features/azkar_streaks/presentation/azkar_streaks_screen.dart';
import '../../features/nearby_mosques/presentation/nearby_mosques_screen.dart';
import '../../features/mushaf/presentation/mushaf_library_screen.dart';
import '../../features/mushaf/presentation/mushaf_pdf_loader_screen.dart';
import '../../features/quran/presentation/bookmarks_list_screen.dart';
import '../../features/quran/presentation/mushaf_screen.dart';
import '../../features/quran_downloads/presentation/quran_downloads_screen.dart';

/// Creates the app router configuration with all routes.
///
/// [storage] is injectable for tests; production code passes the instance
/// resolved from [storageServiceProvider].
GoRouter createRouter({StorageService? storage}) {
  final isFirstLaunch = (storage ?? StorageService.instance)
          .getSetting<bool>(StorageKeys.isFirstLaunch, defaultValue: true) ??
      true;

  return GoRouter(
    initialLocation: isFirstLaunch ? '/onboarding' : '/home',
    routes: [
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
                    pageBuilder: (context, state) {
                      final categoryName =
                          state.uri.queryParameters['name'] ?? 'الأذكار';
                      // Celebration screen keeps its soft fade + rise-in.
                      return CustomTransitionPage(
                        key: state.pageKey,
                        transitionDuration: const Duration(milliseconds: 500),
                        child: AzkarCompletionScreen(
                            categoryName: categoryName),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
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
                      );
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
          GoRoute(
            path: '/notification-status',
            name: 'notification-status',
            builder: (context, state) => const NotificationStatusScreen(),
          ),
          GoRoute(
            path: '/post-prayer-dhikr',
            name: 'post-prayer-dhikr',
            builder: (context, state) {
              final prayer = state.uri.queryParameters['prayer'];
              return PostPrayerDhikrScreen(prayerName: prayer);
            },
          ),
          GoRoute(
            path: '/ramadan',
            name: 'ramadan',
            builder: (context, state) => const RamadanScreen(),
          ),
          GoRoute(
            path: '/khatma',
            name: 'khatma',
            builder: (context, state) => const KhatmaScreen(),
          ),
          GoRoute(
            path: '/asma-allah',
            name: 'asma-allah',
            builder: (context, state) => const AsmaAllahScreen(),
          ),
          GoRoute(
            path: '/hadith-of-day',
            name: 'hadith-of-day',
            builder: (context, state) => const HadithOfDayScreen(),
          ),
          GoRoute(
            path: '/wudu',
            name: 'wudu',
            builder: (context, state) => const WuduScreen(),
          ),
          GoRoute(
            path: '/islamic-calendar',
            name: 'islamic-calendar',
            builder: (context, state) => const IslamicCalendarScreen(),
          ),
          GoRoute(
            path: '/azkar-streaks',
            name: 'azkar-streaks',
            builder: (context, state) => const AzkarStreaksScreen(),
          ),
          GoRoute(
            path: '/nearby-mosques',
            name: 'nearby-mosques',
            builder: (context, state) => const NearbyMosquesScreen(),
          ),
          GoRoute(
            path: '/quran-downloads',
            name: 'quran-downloads',
            builder: (context, state) => const QuranDownloadsScreen(),
          ),
          GoRoute(
            path: '/mushaf-library',
            name: 'mushaf-library',
            builder: (context, state) => const MushafLibraryScreen(),
          ),
        ],
      ),

      // ── Full-screen reading routes (outside the shell — no bottom nav) ──

      // Text-mode Quran pages. `?page=N` opens a specific mushaf page.
      GoRoute(
        path: '/mushaf-text',
        name: 'mushaf-text',
        builder: (context, state) {
          final page =
              int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 1;
          return MushafScreen(initialPage: page);
        },
      ),

      // PDF mushaf reader. `?page=N` opens a specific PDF page; without it
      // the reader resumes from the per-mushaf saved position.
      GoRoute(
        path: '/mushaf-pdf/:mushafId',
        name: 'mushaf-pdf',
        builder: (context, state) {
          final mushafId = state.pathParameters['mushafId'] ?? '';
          final page = int.tryParse(state.uri.queryParameters['page'] ?? '');
          return MushafPdfLoaderScreen(
            mushafId: mushafId,
            initialPdfPage: page,
          );
        },
      ),

      // Saved Quran bookmarks.
      GoRoute(
        path: '/quran-bookmarks',
        name: 'quran-bookmarks',
        builder: (context, state) => const BookmarksListScreen(),
      ),

      // Monthly prayer-times calendar.
      GoRoute(
        path: '/prayer-times-monthly',
        name: 'prayer-times-monthly',
        builder: (context, state) => const MonthlyPrayerTimesScreen(),
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
        location.startsWith('/hajj-umrah') ||
        location.startsWith('/ramadan') ||
        location.startsWith('/khatma') ||
        location.startsWith('/asma-allah') ||
        location.startsWith('/hadith-of-day') ||
        location.startsWith('/wudu') ||
        location.startsWith('/islamic-calendar') ||
        location.startsWith('/azkar-streaks') ||
        location.startsWith('/nearby-mosques') ||
        location.startsWith('/post-prayer-dhikr')) {
      return 1;
    }
    if (location.startsWith('/quran-downloads')) {
      return 2;
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
        // M3 NavigationBar: animated pill indicator, themed in app_theme.
        // A top hairline separates it from content (replaces drop shadow).
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onItemTapped(context, index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: AppStrings.homeTab,
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_stories_outlined),
                selectedIcon: Icon(Icons.auto_stories),
                label: AppStrings.azkarTab,
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: AppStrings.quranTab,
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: AppStrings.settingsTab,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
