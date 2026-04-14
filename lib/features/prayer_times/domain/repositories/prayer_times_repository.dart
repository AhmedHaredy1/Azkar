import '../models/prayer_time.dart';

abstract class PrayerTimesRepository {
  List<PrayerTime> getTodayPrayerTimes(double lat, double lng, {Duration? utcOffset});
  List<PrayerTime> getPrayerTimesForDate(double lat, double lng, DateTime date, {Duration? utcOffset});
  PrayerTime? getNextPrayer(double lat, double lng, {Duration? utcOffset});
}
