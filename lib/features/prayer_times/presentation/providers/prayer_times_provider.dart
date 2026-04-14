import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/prayer_times_repository_impl.dart';
import '../../domain/models/prayer_time.dart';

final prayerTimesRepositoryProvider = Provider<PrayerTimesRepositoryImpl>((ref) {
  final repo = PrayerTimesRepositoryImpl();
  // Apply calculation method from settings
  final settings = ref.watch(settingsProvider);
  repo.setCalculationMethod(settings.calculationMethod);
  return repo;
});

final locationProvider = FutureProvider<Position>((ref) async {
  final settings = ref.watch(settingsProvider);

  // Auto-detect mode: use GPS
  if (settings.locationMode == LocationMode.auto) {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('خدمة الموقع غير مفعّلة. يرجى تفعيلها من إعدادات الجهاز.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض إذن الموقع');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('تم رفض إذن الموقع بشكل دائم');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // Manual mode: use saved location from settings
  if (settings.latitude != null && settings.longitude != null) {
    return Position(
      latitude: settings.latitude!,
      longitude: settings.longitude!,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  throw Exception('يرجى اختيار مدينتك من الإعدادات');
});

/// Tick provider that updates every minute to force prayer time recalculation.
/// This ensures "isNext" and next prayer always reflect the current time.
final _minuteTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

final prayerTimesProvider = FutureProvider<List<PrayerTime>>((ref) async {
  // Watch the minute tick so this provider recomputes every minute
  ref.watch(_minuteTickProvider);
  final position = await ref.watch(locationProvider.future);
  final repo = ref.watch(prayerTimesRepositoryProvider);
  final settings = ref.watch(settingsProvider);
  return repo.getTodayPrayerTimes(position.latitude, position.longitude,
      utcOffset: settings.utcOffset);
});

final nextPrayerProvider = FutureProvider<PrayerTime?>((ref) async {
  // Watch the minute tick so this provider recomputes every minute
  ref.watch(_minuteTickProvider);
  final position = await ref.watch(locationProvider.future);
  final repo = ref.watch(prayerTimesRepositoryProvider);
  final settings = ref.watch(settingsProvider);
  return repo.getNextPrayer(position.latitude, position.longitude,
      utcOffset: settings.utcOffset);
});
