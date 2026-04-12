import '../models/prayer_time.dart';

abstract class PrayerTimesRepository {
  List<PrayerTime> getTodayPrayerTimes(double lat, double lng);
  List<PrayerTime> getPrayerTimesForDate(double lat, double lng, DateTime date);
  PrayerTime? getNextPrayer(double lat, double lng);
}
