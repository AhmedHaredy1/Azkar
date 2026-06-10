import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/di/service_providers.dart';
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
  late final _router =
      createRouter(storage: ref.read(storageServiceProvider));
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

    // Prompt for permissions on first launch so notifications actually fire
    // on Android 13+ (where POST_NOTIFICATIONS is denied by default) and so
    // exact-alarm + battery-optimization whitelist are in place before we
    // schedule anything. Idempotent — no prompt when already granted.
    await manager.requestPermissions();

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
    // ── Prayer-time adhan: play audio in-app when tapped ──
    // Notification payloads from prayer scheduling follow the shape
    // `prayer_adhan:<PrayerName>` (e.g. `prayer_adhan:Fajr`) and
    // `prayer_reminder:<PrayerName>` for the 15-min pre-prayer alert.
    // When the user taps a prayer-time notification we also start the
    // in-app adhan via just_audio so they hear it even if the system
    // couldn't play the custom sound on the notification channel
    // (app-private paths don't reliably play as channel sound on newer
    // Android — this is our fallback).
    if (payload.startsWith('prayer_adhan:')) {
      final prayerName = payload.substring('prayer_adhan:'.length);
      final settings = ref.read(settingsProvider);
      if (settings.playAdhan) {
        ref
            .read(adhanAudioServiceProvider)
            .playAdhan(settings.adhanReciterId, isFajr: prayerName == 'Fajr');
      }
    }

    // Delay to ensure router is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Post-prayer dhikr — payload format `post_prayer:<PrayerName>`. When the
      // user taps the post-Fard reminder notification, route directly to the
      // guided counter screen with the prayer pre-selected.
      if (payload.startsWith('post_prayer:')) {
        final prayer = payload.substring('post_prayer:'.length);
        _router.go('/post-prayer-dhikr?prayer=$prayer');
        return;
      }

      // Route to prayer-times for any prayer_* payload, keep legacy value too.
      if (payload == 'prayer_times' ||
          payload.startsWith('prayer_adhan:') ||
          payload.startsWith('prayer_reminder:')) {
        _router.go('/prayer-times');
        return;
      }

      switch (payload) {
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
    // Watching the palette rebuilds MaterialApp.theme so every screen
    // (and every `AppColors.primary` reference) reflects the user's pick.
    final palette = ref.watch(activePaletteProvider);

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
          previous.longitude != next.longitude ||
          previous.utcOffset != next.utcOffset ||
          previous.playAdhan != next.playAdhan ||
          previous.adhanReciterId != next.adhanReciterId ||
          previous.useGlobalReminder != next.useGlobalReminder ||
          previous.reminderMinutesGlobal != next.reminderMinutesGlobal ||
          previous.reminderMinutesFajr != next.reminderMinutesFajr ||
          previous.reminderMinutesDhuhr != next.reminderMinutesDhuhr ||
          previous.reminderMinutesAsr != next.reminderMinutesAsr ||
          previous.reminderMinutesMaghrib != next.reminderMinutesMaghrib ||
          previous.reminderMinutesIsha != next.reminderMinutesIsha ||
          previous.notifyPostPrayerDhikr != next.notifyPostPrayerDhikr ||
          previous.postPrayerDhikrDelayMinutes !=
              next.postPrayerDhikrDelayMinutes;

      if (notifChanged) {
        _rescheduleNotifications();
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(palette),
        themeMode: ThemeMode.light,
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
