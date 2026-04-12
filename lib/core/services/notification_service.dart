import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  bool _initialized = false;

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

  /// Initialize the notification plugin and timezone data.
  Future<void> init() async {
    if (_initialized) return;

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

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    // Check if app was launched from a notification
    final launchDetails =
        await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      launchNotificationResponse =
          launchDetails!.notificationResponse;
    }

    // Create Android notification channels
    await _createAndroidChannels();

    _initialized = true;
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
  Future<void> scheduleNotification({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final isHighImportance = channelId == prayerChannelId;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isHighImportance ? prayerChannelName : azkarChannelName,
      channelDescription:
          isHighImportance ? prayerChannelDescription : azkarChannelDescription,
      importance: isHighImportance ? Importance.high : Importance.defaultImportance,
      priority: isHighImportance ? Priority.high : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
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

    // Convert local DateTime to TZDateTime
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

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
}
