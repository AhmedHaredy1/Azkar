import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'storage_service.dart';

/// Stream controller for notification tap events (app-wide).
/// Used to route to the correct screen when notification is tapped.
final StreamController<String?> notificationTapStream =
    StreamController<String?>.broadcast();

/// Callback for handling notification taps (must be top-level or static).
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  notificationTapStream.add(response.payload);
}

/// Callback for background notification actions (required for Android).
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(
    NotificationResponse response) {
  // Background notification handling — no-op, handled on foreground resume.
}

/// Low-level wrapper around flutter_local_notifications.
/// Handles initialization, channel creation, and scheduling.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Platform channel to the native recovery bridge in MainActivity.kt.
  /// Used to self-heal from corrupted plugin SharedPreferences left behind
  /// by earlier APK versions.
  static const MethodChannel _recoveryChannel =
      MethodChannel('com.ahmedharedy.azkar/notification_recovery');

  bool _initialized = false;
  bool _storageRecovered = false;

  // Android notification channel IDs
  static const String prayerChannelId = 'prayer_times';
  static const String prayerChannelName = 'تنبيهات الصلاة';
  static const String prayerChannelDescription = 'تنبيهات أوقات الصلاة اليومية';

  static const String azkarChannelId = 'azkar_reminders';
  static const String azkarChannelName = 'تذكير الأذكار';
  static const String azkarChannelDescription =
      'تذكير أذكار الصباح والمساء';

  // Notification IDs (unique per notification type)
  static const int fajrNotificationId = 100;
  static const int dhuhrNotificationId = 101;
  static const int asrNotificationId = 102;
  static const int maghribNotificationId = 103;
  static const int ishaNotificationId = 104;
  static const int morningAzkarNotificationId = 200;
  static const int eveningAzkarNotificationId = 201;

  /// The notification response received when the app launched from a notification.
  NotificationResponse? launchNotificationResponse;

  /// One-time recovery flag. The previous APK scheduled notifications with a
  /// custom `UriAndroidNotificationSound(file://...)` that the plugin (v18)
  /// can no longer deserialize, throwing "Missing type parameter" on every
  /// call — including from inside `initialize()` itself. We must wipe the
  /// plugin's persisted state BEFORE init runs, gated by this Hive flag so
  /// it only happens once per app install/update cycle.
  static const String _recoveryFlagKey = 'notification_storage_recovered_v2';

  /// Initialize the notification plugin and timezone data.
  Future<void> init() async {
    if (_initialized) return;

    // ── Pre-init storage recovery (one-time per install) ──
    // Run BEFORE `_plugin.initialize()` because the plugin reads its
    // persisted scheduled notifications during init, and a single corrupt
    // record (e.g., a UriAndroidNotificationSound from the old APK) makes
    // every subsequent plugin call throw. Gated by Hive so we only wipe
    // once after this update.
    try {
      final storage = StorageService.instance;
      final alreadyRecovered =
          storage.getSetting<bool>(_recoveryFlagKey, defaultValue: false) ??
              false;
      if (!alreadyRecovered && Platform.isAndroid) {
        await _recoveryChannel
            .invokeMethod<bool>('clearNotificationStorage')
            .timeout(const Duration(seconds: 3));
        await storage.putSetting(_recoveryFlagKey, true);
        _storageRecovered = true;
      }
    } catch (_) {
      // Non-fatal — fall through and try the runtime probe below.
    }

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Plugin initialize is wrapped — if it still throws despite the pre-init
    // wipe (e.g., on a device where the cleanup native handler wasn't there),
    // we attempt a second recovery and retry once.
    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            onDidReceiveBackgroundNotificationResponse,
      );
    } catch (e) {
      if (e.toString().toLowerCase().contains('missing type parameter')) {
        await _recoveryChannel
            .invokeMethod<bool>('clearNotificationStorage')
            .timeout(const Duration(seconds: 3))
            .catchError((_) => false);
        await _plugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
          onDidReceiveBackgroundNotificationResponse:
              onDidReceiveBackgroundNotificationResponse,
        );
      } else {
        rethrow;
      }
    }

    // Check if app was launched from a notification
    try {
      final launchDetails =
          await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        launchNotificationResponse = launchDetails!.notificationResponse;
      }
    } catch (_) {
      // Non-fatal — recovery probe below handles persistent corruption.
    }

    // Create Android notification channels
    try {
      await _createAndroidChannels();
    } catch (_) {}

    // Final probe: if anything still fails with "Missing type parameter",
    // recover once more so subsequent operations succeed.
    await _recoverCorruptStorageIfNeeded();

    _initialized = true;
  }

  /// Probe the plugin's scheduled-notification store; on the known
  /// "Missing type parameter" failure, ask the native recovery bridge to
  /// clear the plugin's SharedPreferences, then retry.
  Future<void> _recoverCorruptStorageIfNeeded() async {
    if (!Platform.isAndroid || _storageRecovered) return;
    try {
      await _plugin.pendingNotificationRequests();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Missing type parameter') ||
          msg.contains('missing type parameter')) {
        try {
          await _recoveryChannel.invokeMethod<bool>('clearNotificationStorage');
          _storageRecovered = true;
        } catch (_) {
          // Native handler not registered (older build) — nothing we can do
          // programmatically; the user must clear app data or reinstall.
        }
      }
    }
  }

  /// Exposed so the diagnostic screen can trigger recovery on demand.
  /// Also resets the one-time recovery flag so a future install gets a fresh
  /// chance to self-heal automatically.
  Future<bool> forceStorageRecovery() async {
    if (!Platform.isAndroid) return false;
    try {
      final cleared = await _recoveryChannel
          .invokeMethod<bool>('clearNotificationStorage')
          .timeout(const Duration(seconds: 3));
      _storageRecovered = true;
      try {
        await StorageService.instance.putSetting(_recoveryFlagKey, true);
      } catch (_) {}
      return cleared ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Create required Android notification channels.
  Future<void> _createAndroidChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Prayer times channel (high importance for Adhan)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        prayerChannelId,
        prayerChannelName,
        description: prayerChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Azkar reminders channel (default importance)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        azkarChannelId,
        azkarChannelName,
        description: azkarChannelDescription,
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Request notification permission (Android 13+ / iOS).
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted =
            await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
      return false;
    } else if (Platform.isIOS) {
      final iosPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return false;
    }
    return false;
  }

  /// Check if notification permission is granted (Android 13+).
  Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
    }
    // On older Android or iOS, assume granted unless denied
    return true;
  }

  /// Request exact alarm permission (Android 12+).
  /// Returns true if permission was granted or not needed.
  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted =
            await androidPlugin.requestExactAlarmsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  /// Whether the app is whitelisted from Android's battery optimization.
  /// On non-Android platforms this always returns true.
  ///
  /// Without the whitelist, aggressive OEM skins (Xiaomi, Huawei, Oppo,
  /// OnePlus, Samsung in some modes) will kill scheduled alarms while the
  /// device is idle, so the adhan and 15-min reminders can silently miss.
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Prompt the user to whitelist the app from battery optimization.
  /// On Android 6+ this opens the system dialog; the user must accept.
  /// Returns true if the whitelist is in place afterwards.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Check if exact alarms are permitted (Android 12+).
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.canScheduleExactNotifications() ??
            false;
      }
    }
    return true;
  }

  /// Schedule a notification at a specific date/time.
  ///
  /// [id] must be unique per notification.
  /// [channelId] determines which Android channel to use.
  /// [scheduledTime] is the local DateTime when the notification should fire.
  /// [payload] is passed back on notification tap (used for deep linking).
  /// Schedule a notification at a specific date/time.
  ///
  /// [soundFilePath] — optional local MP3 path used as notification sound
  /// (e.g., cached adhan audio). When provided, a dedicated channel with
  /// alarm-level audio usage is used so the full audio plays.
  Future<void> scheduleNotification({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String? soundFilePath,
  }) async {
    final isHighImportance = channelId == prayerChannelId;

    // NOTE: `soundFilePath` is intentionally ignored here. Passing a custom
    // `UriAndroidNotificationSound(file://…)` causes Android to throw
    // `PlatformException: Missing type parameter` when the plugin later tries
    // to list pending notifications, and the system media service can't read
    // app-private files anyway. Instead we play the adhan audio in-app via
    // `AdhanAudioService.playAdhan()` when the user taps a `prayer_adhan:*`
    // notification (see `app.dart _handleNotificationDeepLink`). The channel's
    // default high-importance sound still plays on the notification itself.

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isHighImportance ? prayerChannelName : azkarChannelName,
      channelDescription:
          isHighImportance ? prayerChannelDescription : azkarChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Build TZDateTime via the absolute UTC instant. `tz.local` is not set by
    // `initializeTimeZones()` and defaults to UTC, so `TZDateTime.from(dt,
    // tz.local)` would reinterpret the wall clock as UTC and fire at the
    // wrong moment (or in the past → silently dropped). Using the UTC
    // instant avoids needing a device-timezone lookup entirely.
    final utcTime = scheduledTime.toUtc();
    final tzScheduledTime = tz.TZDateTime.utc(
      utcTime.year,
      utcTime.month,
      utcTime.day,
      utcTime.hour,
      utcTime.minute,
      utcTime.second,
      utcTime.millisecond,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: null, // One-shot, we reschedule daily
    );
  }

  /// Cancel a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Get list of pending notification requests (for debugging).
  Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }

  /// Full notification-health snapshot for the diagnostic UI. Each probe is
  /// isolated so one failing call (e.g. a method unsupported on the current
  /// Android version) can't abort the whole snapshot and leave the UI stuck
  /// in a loading state. Any per-probe error is surfaced via [errors] so the
  /// screen can display it instead of hanging.
  Future<NotificationDiagnostics> getDiagnostics() async {
    // Ensure the plugin is initialized before probing — `pendingNotifications`
    // in particular needs a live plugin handle.
    if (!_initialized) {
      try {
        await init();
      } catch (e) {
        // Non-fatal — probes below will still report what they can.
      }
    }

    // Always run recovery check before a diagnostic read — the init-time
    // check might have been skipped or happened before the user accepted
    // permissions, leaving corrupt records in place.
    await _recoverCorruptStorageIfNeeded();

    final errors = <String>[];

    bool notifGranted = false;
    try {
      notifGranted = await isPermissionGranted();
    } catch (e) {
      errors.add('إذن التنبيهات: $e');
    }

    bool exactAllowed = false;
    try {
      exactAllowed = await canScheduleExactAlarms();
    } catch (e) {
      errors.add('المنبهات الدقيقة: $e');
    }

    bool batteryWhitelisted = false;
    try {
      batteryWhitelisted = await isIgnoringBatteryOptimizations();
    } catch (e) {
      errors.add('استثناء البطارية: $e');
    }

    List<PendingNotificationRequest> pending = const [];
    try {
      pending = await getPendingNotifications();
    } catch (e) {
      errors.add('التنبيهات المجدولة: $e');
    }

    return NotificationDiagnostics(
      notificationPermissionGranted: notifGranted,
      exactAlarmsAllowed: exactAllowed,
      batteryOptimizationWhitelisted: batteryWhitelisted,
      pendingNotifications: pending,
      errors: errors,
    );
  }
}

/// Snapshot of notification-system health for the diagnostic screen.
class NotificationDiagnostics {
  final bool notificationPermissionGranted;
  final bool exactAlarmsAllowed;
  final bool batteryOptimizationWhitelisted;
  final List<PendingNotificationRequest> pendingNotifications;
  final List<String> errors;

  const NotificationDiagnostics({
    required this.notificationPermissionGranted,
    required this.exactAlarmsAllowed,
    required this.batteryOptimizationWhitelisted,
    required this.pendingNotifications,
    this.errors = const [],
  });

  bool get allHealthy =>
      notificationPermissionGranted &&
      exactAlarmsAllowed &&
      batteryOptimizationWhitelisted &&
      pendingNotifications.isNotEmpty;
}
