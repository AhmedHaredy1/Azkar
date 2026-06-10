import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/services/adhan_alarm_scheduler.dart';
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

/// Offset added to prayer notification IDs for the 15-min reminder.
const int _reminderIdOffset = 50;

/// Offset added to prayer notification IDs for the post-prayer dhikr reminder.
/// Lands at base 150 (e.g. Fajr post-prayer = 100 + 150 = 250). With day
/// offset × 5 the max id is 284 — comfortably above the azkar range (200–211).
const int _postPrayerIdOffset = 150;

/// Number of days ahead to schedule prayer notifications. Keeps alarms armed
/// even if the user doesn't reopen the app for a while (OEM Doze / background
/// restrictions mean the scheduler only runs when the app is launched or
/// settings change). With [_dayIdMultiplier] = 5, max prayer id = 134 and max
/// reminder id = 184, staying well below the Azkar ids (200+).
const int _scheduleAheadDays = 7;
const int _dayIdMultiplier = 5;

/// Maps prayer name to Arabic notification title.
const Map<String, String> _prayerNotificationTitles = {
  'Fajr': 'حان وقت صلاة الفجر',
  'Dhuhr': 'حان وقت صلاة الظهر',
  'Asr': 'حان وقت صلاة العصر',
  'Maghrib': 'حان وقت صلاة المغرب',
  'Isha': 'حان وقت صلاة العشاء',
};

/// Maps prayer name to its Arabic display name (used in the dynamic reminder
/// body so the wording matches whatever lead time the user picked).
const Map<String, String> _prayerArabicNames = {
  'Fajr': 'الفجر',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

const List<String> _arabicDigits = [
  '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',
];

/// Convert an integer to Arabic-Indic digits (e.g. 15 → ١٥).
String _toArabicNumber(int n) {
  return n
      .toString()
      .split('')
      .map((c) {
        final d = int.tryParse(c);
        return d == null ? c : _arabicDigits[d];
      })
      .join();
}

/// Build the Arabic body string for a pre-prayer reminder.
String _buildReminderBody(String prayerName, int minutes) {
  final ar = _prayerArabicNames[prayerName] ?? 'الصلاة';
  return 'متبقي ${_toArabicNumber(minutes)} دقيقة على صلاة $ar';
}

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
  final AdhanAudioService _adhanAudio;
  final AdhanAlarmScheduler _alarmScheduler;

  NotificationManager({
    NotificationService? service,
    StorageService? storage,
    AdhanAudioService? adhanAudio,
    AdhanAlarmScheduler? alarmScheduler,
  })  : _service = service ?? NotificationService.instance,
        _storage = storage ?? StorageService.instance,
        _adhanAudio = adhanAudio ?? AdhanAudioService.instance,
        _alarmScheduler = alarmScheduler ?? AdhanAlarmScheduler.instance;

  /// Initialize the notification system.
  /// Call this once during app startup.
  Future<void> init() async {
    await _service.init();
  }

  /// Request all necessary permissions so prayer alerts fire reliably even
  /// when the app is closed: POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, and
  /// the battery-optimization whitelist (the last one is what prevents
  /// aggressive OEM skins from silently killing scheduled alarms).
  /// Returns true if notification permission was granted.
  Future<bool> requestPermissions() async {
    final notifGranted = await _service.requestPermission();
    if (notifGranted) {
      // Exact alarms (Android 12+) — required for `exactAllowWhileIdle`.
      await _service.requestExactAlarmPermission();
      // Battery optimization whitelist — required on many OEM skins so the
      // scheduled adhan/reminder alarms actually fire in deep idle.
      if (!await _service.isIgnoringBatteryOptimizations()) {
        await _service.requestIgnoreBatteryOptimizations();
      }
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
    await _adhanAudio.playAdhan(
      settings.adhanReciterId,
      isFajr: isFajr,
    );
  }

  /// Stop any currently playing Adhan.
  Future<void> stopAdhan() async {
    await _adhanAudio.stop();
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

    // Ensure permission — on Android 13+ this is denied by default and nothing
    // fires until granted. Silent early-return here was the primary reason
    // the user never received any alerts; now we prompt instead of giving up.
    final hasPermission = await _service.isPermissionGranted();
    if (!hasPermission) {
      final granted = await _service.requestPermission();
      if (!granted) return;
      // Also grab exact-alarm + battery-opt permissions once we're in prompt
      // mode, so the first-launch flow only asks once.
      await _service.requestExactAlarmPermission();
      if (!await _service.isIgnoringBatteryOptimizations()) {
        await _service.requestIgnoreBatteryOptimizations();
      }
    }

    // Cancel all existing notifications first
    await _service.cancelAllNotifications();
    // Also cancel any previously scheduled native adhan alarms so a reciter
    // change or toggle flip doesn't leave the old one armed.
    await _alarmScheduler.cancelAll();

    // Schedule prayer notifications
    await _schedulePrayerNotifications(settings);

    // Schedule Azkar reminders
    await _scheduleAzkarReminders(settings);
  }

  /// Schedule prayer time notifications for today and tomorrow.
  /// Includes both the adhan notification at prayer time and a 15-minute
  /// reminder before each prayer. The adhan audio itself plays in-app when
  /// the user taps a `prayer_adhan:*` notification — see
  /// `app.dart _handleNotificationDeepLink`.
  Future<void> _schedulePrayerNotifications(
      AppSettingsState settings) async {
    final repo = PrayerTimesRepositoryImpl();
    repo.setCalculationMethod(settings.calculationMethod);

    final now = DateTime.now();

    // Pre-cache the selected adhan MP3 once so every alarm in the horizon can
    // reference the same local file. Fajr has its own melody for some
    // reciters, so we cache both. Skipped entirely when the user turned off
    // adhan playback — the visible notification still fires either way.
    String? adhanMp3Path;
    String? fajrAdhanMp3Path;
    if (settings.playAdhan) {
      adhanMp3Path = await _adhanAudio.cacheAdhanFile(settings.adhanReciterId);
      fajrAdhanMp3Path =
          await _adhanAudio.cacheAdhanFile(settings.adhanReciterId, isFajr: true);
    }

    // Schedule for today (only future prayers) plus the next several days so
    // alarms remain armed even if the user doesn't reopen the app.
    for (var dayOffset = 0; dayOffset < _scheduleAheadDays; dayOffset++) {
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
        final uniqueId = notificationId + (dayOffset * _dayIdMultiplier);

        final title = _prayerNotificationTitles[prayer.name] ?? 'حان وقت الصلاة';
        final timeStr = _formatTime(prayer.time);

        // ── Adhan notification at prayer time ──
        // Fault-tolerant scheduling: one bad time must not abort the whole
        // horizon, or we risk leaving the user with zero notifications.
        try {
          await _service.scheduleNotification(
            id: uniqueId,
            channelId: NotificationService.prayerChannelId,
            title: title,
            body: timeStr,
            scheduledTime: prayer.time,
            payload: 'prayer_adhan:${prayer.name}',
          );
        } catch (_) {}

        // ── Native adhan playback alarm at prayer time ──
        // Fires AdhanAlarmReceiver → AdhanPlayerService which plays the
        // selected reciter's MP3 via MediaPlayer in a foreground service —
        // works even when the app is killed. Only scheduled when adhan
        // playback is enabled and the MP3 was successfully cached.
        final adhanPath =
            prayer.name == 'Fajr' ? fajrAdhanMp3Path : adhanMp3Path;
        if (settings.playAdhan && adhanPath != null) {
          try {
            await _alarmScheduler.schedule(
              id: uniqueId,
              triggerAt: prayer.time,
              mp3Path: adhanPath,
              prayer: _prayerArabicNames[prayer.name] ?? prayer.name,
            );
          } catch (_) {}
        }

        // ── Post-prayer dhikr reminder ──
        // Fires N minutes after the adhan to nudge the user toward the
        // guided أذكار دبر الصلاة flow. Tapping it deep-links into
        // /post-prayer-dhikr?prayer=<Name>.
        if (settings.notifyPostPrayerDhikr &&
            settings.postPrayerDhikrDelayMinutes > 0) {
          final postTime = prayer.time.add(
            Duration(minutes: settings.postPrayerDhikrDelayMinutes),
          );
          if (postTime.isAfter(now)) {
            try {
              await _service.scheduleNotification(
                id: uniqueId + _postPrayerIdOffset,
                channelId: NotificationService.azkarChannelId,
                title: 'أذكار دبر الصلاة',
                body: 'لا تنسَ أذكار ما بعد صلاة '
                    '${_prayerArabicNames[prayer.name] ?? ''}',
                scheduledTime: postTime,
                payload: 'post_prayer:${prayer.name}',
              );
            } catch (_) {}
          }
        }

        // ── Configurable pre-prayer reminder ──
        // Lead time depends on user settings (global vs. per-prayer); 0 means
        // the reminder is disabled for that prayer.
        final leadMinutes = settings.reminderMinutesFor(prayer.name);
        if (leadMinutes > 0) {
          final reminderTime =
              prayer.time.subtract(Duration(minutes: leadMinutes));
          if (reminderTime.isAfter(now)) {
            try {
              await _service.scheduleNotification(
                id: uniqueId + _reminderIdOffset,
                channelId: NotificationService.prayerChannelId,
                title: 'تذكير بالصلاة',
                body: _buildReminderBody(prayer.name, leadMinutes),
                scheduledTime: reminderTime,
                payload: 'prayer_reminder:${prayer.name}',
              );
            } catch (_) {}
          }
        }
      }
    }
  }

  /// Schedule Morning and Evening Azkar reminder notifications.
  Future<void> _scheduleAzkarReminders(AppSettingsState settings) async {
    final now = DateTime.now();

    // Morning Azkar reminder
    if (settings.notifyMorningAzkar) {
      final morningHour = _storage.getSetting<int>(
              StorageKeys.morningAzkarHour,
              defaultValue: 6) ??
          6;
      final morningMinute = _storage.getSetting<int>(
              StorageKeys.morningAzkarMinute,
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
      final eveningHour = _storage.getSetting<int>(
              StorageKeys.eveningAzkarHour,
              defaultValue: 16) ??
          16;
      final eveningMinute = _storage.getSetting<int>(
              StorageKeys.eveningAzkarMinute,
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
    final minuteStr = _toArabicNumber(minute).padLeft(2, '٠');
    return '${_toArabicNumber(displayHour)}:$minuteStr $period';
  }

  /// Cancel all prayer notifications (adhan + 15-min reminders) across the
  /// full [_scheduleAheadDays] horizon.
  Future<void> cancelPrayerNotifications() async {
    for (final id in _prayerNotificationIds.values) {
      for (var dayOffset = 0; dayOffset < _scheduleAheadDays; dayOffset++) {
        final dayId = id + (dayOffset * _dayIdMultiplier);
        await _service.cancelNotification(dayId);
        await _service.cancelNotification(dayId + _reminderIdOffset);
        await _service.cancelNotification(dayId + _postPrayerIdOffset);
      }
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
  return NotificationManager(
    service: ref.watch(notificationServiceProvider),
    storage: ref.watch(storageServiceProvider),
    adhanAudio: ref.watch(adhanAudioServiceProvider),
    alarmScheduler: ref.watch(adhanAlarmSchedulerProvider),
  );
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
