import 'dart:io';

import 'package:flutter/services.dart';

/// Bridge to the native Android AlarmManager + AdhanPlayerService.
/// The Flutter notification plugin can't reliably play app-private MP3 paths
/// as a notification sound on modern Android; this scheduler fires an alarm
/// that starts a foreground service which plays the chosen adhan via
/// MediaPlayer, so the selected adhan is heard even when the app is killed.
class AdhanAlarmScheduler {
  AdhanAlarmScheduler._();
  static final AdhanAlarmScheduler instance = AdhanAlarmScheduler._();

  static const _channel = MethodChannel('com.ahmedharedy.azkar/adhan_alarm');

  Future<bool> schedule({
    required int id,
    required DateTime triggerAt,
    required String mp3Path,
    required String prayer,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('schedule', {
        'id': id,
        'triggerAtMs': triggerAt.millisecondsSinceEpoch,
        'mp3Path': mp3Path,
        'prayer': prayer,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancel(int id) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('cancel', {'id': id});
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelAll() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('cancelAll');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopPlayback() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('stopPlayback');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
