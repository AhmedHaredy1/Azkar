import 'package:adhan/adhan.dart' as adhan;

import '../domain/models/prayer_time.dart';
import '../domain/repositories/prayer_times_repository.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  String _calculationMethod = 'UmmAlQura';

  void setCalculationMethod(String method) {
    _calculationMethod = method;
  }

  adhan.CalculationParameters _getCalculationParams() {
    switch (_calculationMethod) {
      case 'Egyptian':
        return adhan.CalculationMethod.egyptian.getParameters();
      case 'MuslimWorldLeague':
        return adhan.CalculationMethod.muslim_world_league.getParameters();
      case 'Karachi':
        return adhan.CalculationMethod.karachi.getParameters();
      case 'NorthAmerica':
        return adhan.CalculationMethod.north_america.getParameters();
      case 'Dubai':
        return adhan.CalculationMethod.dubai.getParameters();
      case 'Kuwait':
        return adhan.CalculationMethod.kuwait.getParameters();
      case 'Qatar':
        return adhan.CalculationMethod.qatar.getParameters();
      case 'Singapore':
        return adhan.CalculationMethod.singapore.getParameters();
      case 'UmmAlQura':
      default:
        return adhan.CalculationMethod.umm_al_qura.getParameters();
    }
  }

  @override
  List<PrayerTime> getTodayPrayerTimes(double lat, double lng, {Duration? utcOffset}) {
    return getPrayerTimesForDate(lat, lng, DateTime.now(), utcOffset: utcOffset);
  }

  @override
  List<PrayerTime> getPrayerTimesForDate(
      double lat, double lng, DateTime date, {Duration? utcOffset}) {
    final coordinates = adhan.Coordinates(lat, lng);
    final dateComponents =
        adhan.DateComponents(date.year, date.month, date.day);
    final params = _getCalculationParams();

    // Use explicit UTC offset when available so prayer times are correct
    // regardless of the device's timezone setting.
    final adhan.PrayerTimes prayerTimes;
    if (utcOffset != null) {
      prayerTimes = adhan.PrayerTimes.utcOffset(
          coordinates, dateComponents, params, utcOffset);
    } else {
      prayerTimes = adhan.PrayerTimes(coordinates, dateComponents, params);
    }

    final times = <PrayerTime>[
      PrayerTime(name: 'Fajr', nameAr: 'الفجر', time: prayerTimes.fajr),
      PrayerTime(
          name: 'Sunrise', nameAr: 'الشروق', time: prayerTimes.sunrise),
      PrayerTime(name: 'Dhuhr', nameAr: 'الظهر', time: prayerTimes.dhuhr),
      PrayerTime(name: 'Asr', nameAr: 'العصر', time: prayerTimes.asr),
      PrayerTime(
          name: 'Maghrib', nameAr: 'المغرب', time: prayerTimes.maghrib),
      PrayerTime(name: 'Isha', nameAr: 'العشاء', time: prayerTimes.isha),
    ];

    // Determine next prayer relative to the location's current time.
    // When using explicit UTC offset, prayer times are UTC-based with offset
    // applied, so we compare against UTC now + offset for consistency.
    final now = utcOffset != null
        ? DateTime.now().toUtc().add(utcOffset)
        : DateTime.now();
    final nextPrayerTime = _findNextPrayer(times, now);
    if (nextPrayerTime != null) {
      return times.map((pt) {
        if (pt.name == nextPrayerTime.name) {
          return pt.copyWith(isNext: true);
        }
        return pt;
      }).toList();
    }

    return times;
  }

  PrayerTime? _findNextPrayer(List<PrayerTime> times, DateTime now) {
    for (final pt in times) {
      if (pt.time.isAfter(now)) {
        return pt;
      }
    }
    return null;
  }

  @override
  PrayerTime? getNextPrayer(double lat, double lng, {Duration? utcOffset}) {
    final times = getTodayPrayerTimes(lat, lng, utcOffset: utcOffset);
    final now = utcOffset != null
        ? DateTime.now().toUtc().add(utcOffset)
        : DateTime.now();
    for (final pt in times) {
      if (pt.time.isAfter(now)) return pt;
    }
    return null;
  }
}
