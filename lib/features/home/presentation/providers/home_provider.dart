import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../../prayer_times/domain/models/prayer_time.dart';
import '../../../quran/presentation/providers/quran_provider.dart';

// ──────────────────────────────────────────────
// Greeting Provider
// ──────────────────────────────────────────────

class GreetingState {
  final String greeting;
  final String subtitle;
  final bool isMorning; // true = before Dhuhr, false = after

  const GreetingState({
    required this.greeting,
    required this.subtitle,
    required this.isMorning,
  });
}

final greetingProvider = Provider<GreetingState>((ref) {
  final hour = DateTime.now().hour;
  // According to plan: صباح الخير before Dhuhr, مساء الخير after
  // We'll use the actual Dhuhr time if available, otherwise default noon = 12
  final prayerTimesAsync = ref.watch(prayerTimesProvider);

  int dhuhrHour = 12; // default
  prayerTimesAsync.whenData((prayers) {
    for (final p in prayers) {
      if (p.name == 'Dhuhr') {
        dhuhrHour = p.time.hour;
        break;
      }
    }
  });

  final isMorning = hour < dhuhrHour;

  String greeting;
  String subtitle;

  if (hour >= 5 && hour < dhuhrHour) {
    greeting = 'صباح الخير';
    subtitle = 'لا تنسَ أذكار الصباح';
  } else if (hour >= dhuhrHour && hour < 21) {
    greeting = 'مساء الخير';
    subtitle = 'لا تنسَ أذكار المساء';
  } else {
    greeting = 'طابت ليلتك';
    subtitle = 'لا تنسَ أذكار النوم';
  }

  return GreetingState(
    greeting: greeting,
    subtitle: subtitle,
    isMorning: isMorning,
  );
});

// ──────────────────────────────────────────────
// Hijri Date Provider
// ──────────────────────────────────────────────

class HijriDateState {
  final String hijriFormatted; // e.g. "١٤ شوال ١٤٤٧"
  final String gregorianFormatted; // e.g. "الثلاثاء ٧ أبريل ٢٠٢٦"

  const HijriDateState({
    required this.hijriFormatted,
    required this.gregorianFormatted,
  });
}

final hijriDateProvider = Provider<HijriDateState>((ref) {
  final hijri = HijriCalendar.now();
  final now = DateTime.now();

  // Hijri months in Arabic
  const hijriMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  // Gregorian months in Arabic
  const gregorianMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  // Arabic day names
  const dayNames = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  final hijriMonth =
      hijri.hMonth >= 1 && hijri.hMonth <= 12
          ? hijriMonths[hijri.hMonth - 1]
          : '';
  final hijriFormatted = '${hijri.hDay} $hijriMonth ${hijri.hYear} هـ';

  final dayName = dayNames[now.weekday - 1];
  final gregMonth = gregorianMonths[now.month - 1];
  final gregorianFormatted = '$dayName ${now.day} $gregMonth ${now.year}';

  return HijriDateState(
    hijriFormatted: hijriFormatted,
    gregorianFormatted: gregorianFormatted,
  );
});

// ──────────────────────────────────────────────
// Next Prayer Countdown Provider
// ──────────────────────────────────────────────

class PrayerCountdownState {
  final String prayerNameAr;
  final String prayerName;
  final DateTime? prayerTime;
  final Duration remaining;
  final bool hasData;

  const PrayerCountdownState({
    this.prayerNameAr = '',
    this.prayerName = '',
    this.prayerTime,
    this.remaining = Duration.zero,
    this.hasData = false,
  });

  String get formattedTime {
    if (!hasData || prayerTime == null) return '--:--';
    final h = prayerTime!.hour;
    final m = prayerTime!.minute;
    final period = h >= 12 ? 'م' : 'ص';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${hour12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  String get formattedCountdown {
    if (!hasData) return '--:--:--';
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class PrayerCountdownNotifier extends StateNotifier<PrayerCountdownState> {
  Timer? _timer;
  final Ref _ref;

  PrayerCountdownNotifier(this._ref)
    : super(const PrayerCountdownState(hasData: false)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final nextPrayer = await _ref.read(nextPrayerProvider.future);
      if (nextPrayer != null) {
        _updateState(nextPrayer);
        _startTimer(nextPrayer);
      } else {
        // All prayers passed for today — show tomorrow's Fajr
        // For now just show no data
        state = const PrayerCountdownState(hasData: false);
      }
    } catch (_) {
      state = const PrayerCountdownState(hasData: false);
    }
  }

  void _updateState(PrayerTime prayer) {
    final now = DateTime.now();
    final remaining = prayer.time.difference(now);
    state = PrayerCountdownState(
      prayerNameAr: prayer.nameAr,
      prayerName: prayer.name,
      prayerTime: prayer.time,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      hasData: true,
    );
  }

  void _startTimer(PrayerTime prayer) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final remaining = prayer.time.difference(now);
      if (remaining.isNegative) {
        _timer?.cancel();
        // Refresh to get the next prayer
        _init();
        return;
      }
      state = PrayerCountdownState(
        prayerNameAr: prayer.nameAr,
        prayerName: prayer.name,
        prayerTime: prayer.time,
        remaining: remaining,
        hasData: true,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final prayerCountdownProvider =
    StateNotifierProvider<PrayerCountdownNotifier, PrayerCountdownState>((ref) {
      return PrayerCountdownNotifier(ref);
    });

// ──────────────────────────────────────────────
// Daily Ayah Provider
// ──────────────────────────────────────────────

class DailyAyahState {
  final String ayahText;
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final bool hasData;

  const DailyAyahState({
    this.ayahText = '',
    this.surahName = '',
    this.surahNumber = 0,
    this.ayahNumber = 0,
    this.hasData = false,
  });
}

final dailyAyahProvider = FutureProvider<DailyAyahState>((ref) async {
  try {
    final localSource = ref.read(quranLocalSourceProvider);
    final surahs = await localSource.loadSurahs();

    if (surahs.isEmpty) {
      return const DailyAyahState(hasData: false);
    }

    // Date-based seed so ayah changes daily but stays consistent within the same day
    final now = DateTime.now();
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(dateSeed);

    // Collect all ayahs count
    int totalAyahs = 0;
    for (final surah in surahs) {
      totalAyahs += surah.ayahs.length;
    }

    if (totalAyahs == 0) {
      return const DailyAyahState(hasData: false);
    }

    // Pick a random ayah from the whole Quran
    int targetIndex = random.nextInt(totalAyahs);
    int accumulated = 0;

    for (final surah in surahs) {
      if (accumulated + surah.ayahs.length > targetIndex) {
        final ayahIndex = targetIndex - accumulated;
        final ayah = surah.ayahs[ayahIndex];
        return DailyAyahState(
          ayahText: ayah.textAr,
          surahName: surah.nameAr,
          surahNumber: surah.number,
          ayahNumber: ayah.number,
          hasData: true,
        );
      }
      accumulated += surah.ayahs.length;
    }

    return const DailyAyahState(hasData: false);
  } catch (_) {
    return const DailyAyahState(hasData: false);
  }
});

// ──────────────────────────────────────────────
// Morning/Evening Azkar Context Provider
// ──────────────────────────────────────────────
// Returns true if it's morning (before Dhuhr), false if evening (after Dhuhr)

final isMorningProvider = Provider<bool>((ref) {
  final greeting = ref.watch(greetingProvider);
  return greeting.isMorning;
});
