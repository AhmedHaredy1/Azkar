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
  List<PrayerTime> getTodayPrayerTimes(double lat, double lng) {
    return getPrayerTimesForDate(lat, lng, DateTime.now());
  }

  @override
  List<PrayerTime> getPrayerTimesForDate(
      double lat, double lng, DateTime date) {
    final coordinates = adhan.Coordinates(lat, lng);
    final dateComponents =
        adhan.DateComponents(date.year, date.month, date.day);
    final params = _getCalculationParams();
    final prayerTimes =
        adhan.PrayerTimes(coordinates, dateComponents, params);

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

    // Determine next prayer (relative to now)
    final now = DateTime.now();
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
  PrayerTime? getNextPrayer(double lat, double lng) {
    final times = getTodayPrayerTimes(lat, lng);
    final now = DateTime.now();
    for (final pt in times) {
      if (pt.time.isAfter(now)) return pt;
    }
    return null;
  }
}
