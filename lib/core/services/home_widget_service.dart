import 'dart:async';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

/// Pushes the latest prayer-time + dhikr snapshot to the Android home-screen
/// widget. Safe to call from anywhere — no-ops on non-Android.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const _androidWidget = 'PrayerWidgetProvider';

  Future<void> update({
    required String nextPrayerName,
    required String nextPrayerTime,
    required String countdown,
    required String dhikr,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await HomeWidget.saveWidgetData<String>(
        'next_prayer_name',
        nextPrayerName,
      );
      await HomeWidget.saveWidgetData<String>(
        'next_prayer_time',
        nextPrayerTime,
      );
      await HomeWidget.saveWidgetData<String>(
        'next_prayer_countdown',
        countdown,
      );
      await HomeWidget.saveWidgetData<String>('current_dhikr', dhikr);
      await HomeWidget.updateWidget(
        androidName: _androidWidget,
        qualifiedAndroidName:
            'com.ahmedharedy.azkar.PrayerWidgetProvider',
      );
    } catch (_) {
      // Best effort — widget updates must never crash the host app.
    }
  }
}
