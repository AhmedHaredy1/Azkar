import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/adhan_alarm_scheduler.dart';
import '../services/adhan_audio_service.dart';
import '../services/home_widget_service.dart';
import '../services/notification_service.dart';
import '../services/surah_download_service.dart';
import '../services/tafsir_service.dart';

export '../services/storage_service.dart' show storageServiceProvider;

/// Riverpod entry points for the app-wide services.
///
/// Feature code must resolve services through these providers (via
/// `ref.read`/`ref.watch`) instead of touching the `.instance` singletons —
/// the providers are overridable in tests and give the container lifecycle
/// control. The `.instance` fields remain only for contexts that have no
/// provider scope: `main()` bootstrap, background isolate entry points, and
/// static platform-channel callbacks.

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final adhanAlarmSchedulerProvider = Provider<AdhanAlarmScheduler>((ref) {
  return AdhanAlarmScheduler.instance;
});

final adhanAudioServiceProvider = Provider<AdhanAudioService>((ref) {
  return AdhanAudioService.instance;
});

final surahDownloadServiceProvider = Provider<SurahDownloadService>((ref) {
  return SurahDownloadService.instance;
});

final tafsirServiceProvider = Provider<TafsirService>((ref) {
  return TafsirService.instance;
});

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService.instance;
});
