import '../models/prayer_time.dart';

abstract class PrayerTimesRepository {
  List<PrayerTime> getTodayPrayerTimes(double lat, double lng);
  PrayerTime? getNextPrayer(double lat, double lng);
}
