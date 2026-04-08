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
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('خدمة الموقع غير مفعّلة');
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
});

final prayerTimesProvider = FutureProvider<List<PrayerTime>>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final repo = ref.watch(prayerTimesRepositoryProvider);
  return repo.getTodayPrayerTimes(position.latitude, position.longitude);
});

final nextPrayerProvider = FutureProvider<PrayerTime?>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final repo = ref.watch(prayerTimesRepositoryProvider);
  return repo.getNextPrayer(position.latitude, position.longitude);
});
