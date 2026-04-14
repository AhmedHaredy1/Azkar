import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/adhan_audio_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../prayer_times/data/prayer_times_repository_impl.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Maps prayer English name to notification ID.
const Map<String, int> _prayerNotificationIds = {
  'Fajr': NotificationService.fajrNotificationId,
  'Dhuhr': NotificationService.dhuhrNotificationId,
  'Asr': NotificationService.asrNotificationId,
  'Maghrib': NotificationService.maghribNotificationId,
  'Isha': NotificationService.ishaNotificationId,
};

/// Maps prayer name to Arabic notification title.
const Map<String, String> _prayerNotificationTitles = {
  'Fajr': 'حان وقت صلاة الفجر',
  'Dhuhr': 'حان وقت صلاة الظهر',
  'Asr': 'حان وقت صلاة العصر',
  'Maghrib': 'حان وقت صلاة المغرب',
  'Isha': 'حان وقت صلاة العشاء',
};

/// Maps prayer name to toggle key in settings.
const Map<String, String> _prayerSettingsKeys = {
  'Fajr': 'fajr',
  'Dhuhr': 'dhuhr',
  'Asr': 'asr',
  'Maghrib': 'maghrib',
  'Isha': 'isha',
};

/// Manages scheduling and cancelling of all notifications.
/// Reuses prayer times calculation and settings toggles.
class NotificationManager {
  final NotificationService _service;
  final StorageService _storage;

  NotificationManager({
    NotificationService? service,
    StorageService? storage,
  })  : _service = service ?? NotificationService.instance,
        _storage = storage ?? StorageService.instance;

  /// Initialize the notification system.
  /// Call this once during app startup.
  Future<void> init() async {
    await _service.init();
  }

  /// Request all necessary permissions (notification + exact alarm).
  /// Returns true if notification permission was granted.
  Future<bool> requestPermissions() async {
    final notifGranted = await _service.requestPermission();
    if (notifGranted) {
      // Also request exact alarm permission for Android 12+
      await _service.requestExactAlarmPermission();
    }
    return notifGranted;
  }

  /// Check if notification permission is granted.
  Future<bool> isPermissionGranted() async {
    return _service.isPermissionGranted();
  }

  /// Play the Adhan audio if enabled in settings.
  /// Called when a prayer notification fires while the app is open.
  Future<void> playAdhanIfEnabled(AppSettingsState settings, {bool isFajr = false}) async {
    if (!settings.playAdhan) return;
    await AdhanAudioService.instance.playAdhan(
      settings.adhanReciterId,
      isFajr: isFajr,
    );
  }

  /// Stop any currently playing Adhan.
  Future<void> stopAdhan() async {
    await AdhanAudioService.instance.stop();
  }

  /// Reschedule ALL notifications based on current settings and prayer times.
  /// This should be called:
  /// - When the app opens (to recalculate prayer times)
  /// - When a notification toggle changes
  /// - When the calculation method changes
  /// - When location changes
  Future<void> rescheduleAll(AppSettingsState settings) async {
    // Check if we have location
    if (settings.latitude == null || settings.longitude == null) {
      return;
    }

    // Check permission
    final hasPermission = await _service.isPermissionGranted();
    if (!hasPermission) {
      return;
    }

    // Cancel all existing notifications first
    await _service.cancelAllNotifications();

    // Schedule prayer notifications
    await _schedulePrayerNotifications(settings);

    // Schedule Azkar reminders
    await _scheduleAzkarReminders(settings);
  }

  /// Schedule prayer time notifications for today and tomorrow.
  Future<void> _schedulePrayerNotifications(
      AppSettingsState settings) async {
    final repo = PrayerTimesRepositoryImpl();
    repo.setCalculationMethod(settings.calculationMethod);

    final now = DateTime.now();

    // Schedule for today (only future prayers) and tomorrow
    for (final dayOffset in [0, 1]) {
      final date = now.add(Duration(days: dayOffset));
      final times = repo.getPrayerTimesForDate(
        settings.latitude!,
        settings.longitude!,
        date,
        utcOffset: settings.utcOffset,
      );

      for (final prayer in times) {
        // Skip Sunrise — no notification for it
        if (prayer.name == 'Sunrise') continue;

        // Check if this prayer's notification is enabled
        final toggleKey = _prayerSettingsKeys[prayer.name];
        if (toggleKey == null) continue;

        final isEnabled = _isPrayerNotificationEnabled(settings, toggleKey);
        if (!isEnabled) continue;

        // Skip past times
        if (prayer.time.isBefore(now)) continue;

        final notificationId = _prayerNotificationIds[prayer.name];
        if (notificationId == null) continue;

        // Use a unique ID: base ID + day offset to avoid overwriting
        final uniqueId = notificationId + (dayOffset * 10);

        final title = _prayerNotificationTitles[prayer.name] ?? 'حان وقت الصلاة';
        final timeStr = _formatTime(prayer.time);

        await _service.scheduleNotification(
          id: uniqueId,
          channelId: NotificationService.prayerChannelId,
          title: title,
          body: timeStr,
          scheduledTime: prayer.time,
          payload: 'prayer_times',
        );
      }
    }
  }

  /// Schedule Morning and Evening Azkar reminder notifications.
  Future<void> _scheduleAzkarReminders(AppSettingsState settings) async {
    final now = DateTime.now();

    // Morning Azkar reminder
    if (settings.notifyMorningAzkar) {
      final morningHour = _storage.getSetting<int>('morningAzkarHour',
              defaultValue: 6) ??
          6;
      final morningMinute = _storage.getSetting<int>(
              'morningAzkarMinute',
              defaultValue: 0) ??
          0;

      // Schedule for today (if not past) and tomorrow
      for (final dayOffset in [0, 1]) {
        final date = now.add(Duration(days: dayOffset));
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          morningHour,
          morningMinute,
        );

        if (scheduledTime.isAfter(now)) {
          await _service.scheduleNotification(
            id: NotificationService.morningAzkarNotificationId +
                (dayOffset * 10),
            channelId: NotificationService.azkarChannelId,
            title: 'أذكار الصباح',
            body: 'حان وقت أذكار الصباح، ابدأ الآن',
            scheduledTime: scheduledTime,
            payload: 'azkar/morning',
          );
          break; // Only schedule the next upcoming one
        }
      }
    }

    // Evening Azkar reminder
    if (settings.notifyEveningAzkar) {
      final eveningHour = _storage.getSetting<int>('eveningAzkarHour',
              defaultValue: 16) ??
          16;
      final eveningMinute = _storage.getSetting<int>(
              'eveningAzkarMinute',
              defaultValue: 0) ??
          0;

      for (final dayOffset in [0, 1]) {
        final date = now.add(Duration(days: dayOffset));
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          eveningHour,
          eveningMinute,
        );

        if (scheduledTime.isAfter(now)) {
          await _service.scheduleNotification(
            id: NotificationService.eveningAzkarNotificationId +
                (dayOffset * 10),
            channelId: NotificationService.azkarChannelId,
            title: 'أذكار المساء',
            body: 'حان وقت أذكار المساء، ابدأ الآن',
            scheduledTime: scheduledTime,
            payload: 'azkar/evening',
          );
          break; // Only schedule the next upcoming one
        }
      }
    }
  }

  /// Check if a specific prayer notification is enabled in settings.
  bool _isPrayerNotificationEnabled(
      AppSettingsState settings, String key) {
    switch (key) {
      case 'fajr':
        return settings.notifyFajr;
      case 'dhuhr':
        return settings.notifyDhuhr;
      case 'asr':
        return settings.notifyAsr;
      case 'maghrib':
        return settings.notifyMaghrib;
      case 'isha':
        return settings.notifyIsha;
      default:
        return false;
    }
  }

  /// Format a DateTime as Arabic-friendly time string (e.g., "٤:٣٢ ص").
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? 'ص' : 'م';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  /// Cancel all prayer notifications.
  Future<void> cancelPrayerNotifications() async {
    for (final id in _prayerNotificationIds.values) {
      await _service.cancelNotification(id);
      await _service.cancelNotification(id + 10); // Tomorrow's
    }
  }

  /// Cancel all Azkar reminder notifications.
  Future<void> cancelAzkarNotifications() async {
    await _service.cancelNotification(
        NotificationService.morningAzkarNotificationId);
    await _service.cancelNotification(
        NotificationService.morningAzkarNotificationId + 10);
    await _service.cancelNotification(
        NotificationService.eveningAzkarNotificationId);
    await _service.cancelNotification(
        NotificationService.eveningAzkarNotificationId + 10);
  }

  /// Get the launch notification payload (if app was launched from a notification).
  String? getLaunchPayload() {
    return _service.launchNotificationResponse?.payload;
  }
}

// ─── Riverpod Providers ────────────────────────────────────────────────

/// Singleton provider for the NotificationManager.
final notificationManagerProvider = Provider<NotificationManager>((ref) {
  return NotificationManager();
});

/// Provider that initializes notifications and schedules them.
/// Watches settings to reschedule when toggles change.
final notificationSchedulerProvider = FutureProvider<void>((ref) async {
  final manager = ref.read(notificationManagerProvider);
  final settings = ref.watch(settingsProvider);

  // Initialize the notification system
  await manager.init();

  // Reschedule all notifications based on current settings
  await manager.rescheduleAll(settings);
});

/// Provider to check if notification permission is granted.
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  final manager = ref.read(notificationManagerProvider);
  await manager.init();
  return manager.isPermissionGranted();
});
