import 'dart:async';
import 'dart:math';

import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';

/// Checks if the device has a compass sensor
final compassAvailableProvider = FutureProvider<bool>((ref) async {
  // FlutterCompass.events will be null if no sensor is available
  final events = FlutterCompass.events;
  if (events == null) return false;

  // Try listening for a short time — if no event comes, sensor may be absent
  try {
    final event = await events.first.timeout(
      const Duration(seconds: 3),
      onTimeout: () => throw TimeoutException('No compass data'),
    );
    return event.heading != null;
  } catch (_) {
    return false;
  }
});

/// Compass accuracy provider (null = unknown, low accuracy = needs calibration)
final compassAccuracyProvider = StreamProvider<double?>((ref) {
  return FlutterCompass.events?.map((event) => event.accuracy) ??
      const Stream.empty();
});

final compassHeadingProvider = StreamProvider<double>((ref) {
  return FlutterCompass.events?.map((event) => event.heading ?? 0.0) ??
      const Stream.empty();
});

final qiblaDirectionProvider = FutureProvider<double>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final coordinates = adhan.Coordinates(position.latitude, position.longitude);
  final qibla = adhan.Qibla(coordinates);
  return qibla.direction;
});

/// Combined provider: returns the angle to rotate compass needle
/// so that it points toward Qibla
final qiblaCompassAngleProvider = Provider<AsyncValue<double>>((ref) {
  final headingAsync = ref.watch(compassHeadingProvider);
  final qiblaAsync = ref.watch(qiblaDirectionProvider);

  return headingAsync.when(
    data: (heading) {
      return qiblaAsync.when(
        data: (qiblaDirection) {
          final angle = (qiblaDirection - heading) * (pi / 180);
          return AsyncValue.data(angle);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
