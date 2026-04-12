import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

class AzkarApp extends ConsumerStatefulWidget {
  const AzkarApp({super.key});

  @override
  ConsumerState<AzkarApp> createState() => _AzkarAppState();
}

class _AzkarAppState extends ConsumerState<AzkarApp>
    with WidgetsBindingObserver {
  late final _router = createRouter();
  StreamSubscription<String?>? _notificationTapSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for notification taps while the app is running
    _notificationTapSubscription =
        notificationTapStream.stream.listen((payload) {
      if (payload != null) {
        _handleNotificationDeepLink(payload);
      }
    });

    // Initialize notifications after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reschedule notifications when app comes to foreground
      // (handles timezone/location changes, travel, etc.)
      _rescheduleNotifications();
    }
  }

  Future<void> _initNotifications() async {
    final manager = ref.read(notificationManagerProvider);
    await manager.init();

    // Handle deep link from notification that launched the app
    final launchPayload = manager.getLaunchPayload();
    if (launchPayload != null) {
      _handleNotificationDeepLink(launchPayload);
    }

    // Schedule all notifications
    await _rescheduleNotifications();
  }

  Future<void> _rescheduleNotifications() async {
    try {
      final manager = ref.read(notificationManagerProvider);
      final settings = ref.read(settingsProvider);
      await manager.rescheduleAll(settings);
    } catch (_) {
      // Notification rescheduling failed silently — will retry on next app open.
    }
  }

  /// Navigate to the correct screen based on notification payload.
  void _handleNotificationDeepLink(String payload) {
    // Delay to ensure router is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      switch (payload) {
        case 'prayer_times':
          _router.go('/prayer-times');
        case 'azkar/morning':
          _router.go('/azkar/morning');
        case 'azkar/evening':
          _router.go('/azkar/evening');
        default:
          // Unknown payload — stay on current screen
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Listen for settings changes to reschedule notifications
    ref.listen(settingsProvider, (previous, next) {
      if (previous == null) return;

      // Check if any notification-related setting changed
      final notifChanged = previous.notifyFajr != next.notifyFajr ||
          previous.notifyDhuhr != next.notifyDhuhr ||
          previous.notifyAsr != next.notifyAsr ||
          previous.notifyMaghrib != next.notifyMaghrib ||
          previous.notifyIsha != next.notifyIsha ||
          previous.notifyMorningAzkar != next.notifyMorningAzkar ||
          previous.notifyEveningAzkar != next.notifyEveningAzkar ||
          previous.calculationMethod != next.calculationMethod ||
          previous.latitude != next.latitude ||
          previous.longitude != next.longitude;

      if (notifChanged) {
        _rescheduleNotifications();
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: _router,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
