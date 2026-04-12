import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await StorageService.instance.init();

  // Initialize notification service (channels, timezone data)
  await NotificationService.instance.init();

  runApp(
    const ProviderScope(
      child: AzkarApp(),
    ),
  );
}
