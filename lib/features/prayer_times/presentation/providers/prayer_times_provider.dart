import 'dart:async';
import 'dart:math' as math;

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

/// Emits whenever the device's location service transitions to enabled.
/// Used to auto-refresh [locationProvider] when the user turns GPS back on,
/// without any manual action.
final _gpsEnabledEventsProvider = StreamProvider<DateTime>((ref) {
  return Geolocator.getServiceStatusStream()
      .where((status) => status == ServiceStatus.enabled)
      .map((_) => DateTime.now());
});

/// Resolves the user's coordinates with graceful GPS fallback.
///
/// In auto mode, tries a fresh GPS fix. On any failure (service off,
/// permission denied, timeout, …) falls back to the last stored coordinates
/// so prayer times and the countdown keep working without interruption.
/// When GPS is re-enabled it is automatically retried.
///
/// In manual mode, always returns the stored coordinates.
final locationProvider = FutureProvider<Position>((ref) async {
  // Re-run whenever GPS service becomes enabled so we pick up a fresh fix
  // as soon as the user turns location back on.
  ref.watch(_gpsEnabledEventsProvider);

  final mode = ref.watch(settingsProvider.select((s) => s.locationMode));
  final cached = ref.watch(
    settingsProvider.select(
      (s) => (s.latitude != null && s.longitude != null)
          ? (s.latitude!, s.longitude!)
          : null,
    ),
  );

  Position cachedPosition() => Position(
        latitude: cached!.$1,
        longitude: cached.$2,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  // Manual mode: only stored coordinates are ever used.
  if (mode == LocationMode.manual) {
    if (cached != null) return cachedPosition();
    throw Exception('يرجى اختيار مدينتك من الإعدادات');
  }

  // Auto mode: attempt a live GPS fix; any failure falls back to the cache.
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (cached != null) return cachedPosition();
      throw Exception(
          'خدمة الموقع غير مفعّلة. يرجى تفعيلها من إعدادات الجهاز.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (cached != null) return cachedPosition();
      throw Exception('تم رفض إذن الموقع');
    }

    final fix = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    // Persist the fresh fix when there is no cache yet or the user has
    // moved more than ~500m since the last saved point. Small jitter is
    // ignored to avoid a rebuild loop on every GPS call.
    final shouldPersist = cached == null ||
        _distanceMeters(cached.$1, cached.$2, fix.latitude, fix.longitude) >
            500;
    if (shouldPersist) {
      // Use setLocation so cityName/countryName/utcOffset (populated by
      // onboarding or the settings screen) are preserved — setLocation's
      // copyWith treats nulls as "keep existing".
      unawaited(
        ref
            .read(settingsProvider.notifier)
            .setLocation(fix.latitude, fix.longitude),
      );
    }

    return fix;
  } catch (_) {
    if (cached != null) return cachedPosition();
    rethrow;
  }
});

/// Haversine distance in meters. Used only to decide whether a GPS fix
/// represents a real move vs. accuracy jitter.
double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

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
