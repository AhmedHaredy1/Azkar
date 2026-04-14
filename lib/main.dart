import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/global_audio_handler.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await StorageService.instance.init();

  // Initialize notification service (channels, timezone data)
  await NotificationService.instance.init();

  // Initialize audio service for background playback & lock screen controls
  final audioHandler = await AudioService.init(
    builder: () => GlobalAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.ahmedharedy.azkar.audio',
      androidNotificationChannelName: 'حصن المسلم',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        globalAudioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const AzkarApp(),
    ),
  );
}
