import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../../prayer_times/domain/models/prayer_time.dart';
import '../../../quran/presentation/providers/quran_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

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

/// Emits the current hour, re-fires whenever the hour changes.
/// Forces downstream providers (greeting, isMorning) to recalculate
/// so the Azkar shortcut card always matches the current time-of-day.
final currentHourProvider = StreamProvider<int>((ref) {
  final controller = StreamController<int>();
  void tick() {
    final now = DateTime.now();
    controller.add(now.hour);
    // Schedule next tick at the start of the next hour.
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final delay = nextHour.difference(now);
    Future.delayed(delay, () {
      if (!controller.isClosed) tick();
    });
  }

  tick();
  ref.onDispose(() => controller.close());
  return controller.stream;
});

final greetingProvider = Provider<GreetingState>((ref) {
  // Watch the hour ticker so we recalculate when the hour rolls over.
  final hourAsync = ref.watch(currentHourProvider);
  final hour = hourAsync.valueOrNull ?? DateTime.now().hour;
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

  // Evening Azkar start after Asr, Morning Azkar start after Fajr.
  int asrHour = 15; // default
  int fajrHour = 5; // default
  prayerTimesAsync.whenData((prayers) {
    for (final p in prayers) {
      if (p.name == 'Asr') asrHour = p.time.hour;
      if (p.name == 'Fajr') fajrHour = p.time.hour;
    }
  });

  int ishaHour = 20; // default
  prayerTimesAsync.whenData((prayers) {
    for (final p in prayers) {
      if (p.name == 'Isha') ishaHour = p.time.hour;
    }
  });

  // Morning period: from Fajr until Asr → show أذكار الصباح
  // Evening period: from Asr onward → show أذكار المساء
  final isMorning = hour >= fajrHour && hour < asrHour;

  // Pre-Fajr window (roughly 2 hours before Fajr) → suggest wake-up azkar
  // so the greeting stops advertising "morning azkar" at 3 AM.
  final preFajrHour = (fajrHour - 2) % 24;

  String greeting;
  String subtitle;

  if (hour >= fajrHour && hour < dhuhrHour) {
    greeting = 'صباح الخير';
    subtitle = 'لا تنسَ أذكار الصباح';
  } else if (hour >= dhuhrHour && hour < asrHour) {
    greeting = 'طاب يومك';
    subtitle = 'لا تنسَ أذكار الصباح';
  } else if (hour >= asrHour && hour < ishaHour) {
    greeting = 'مساء الخير';
    subtitle = 'لا تنسَ أذكار المساء';
  } else if (hour >= preFajrHour && hour < fajrHour) {
    greeting = 'صباح النور';
    subtitle = 'لا تنسَ أذكار الاستيقاظ من النوم';
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

    // Listen to nextPrayerProvider changes (triggered by location/settings changes)
    // so the countdown automatically refreshes when the user changes location.
    _ref.listen<AsyncValue<PrayerTime?>>(nextPrayerProvider, (prev, next) {
      next.whenData((nextPrayer) {
        if (nextPrayer != null) {
          _updateState(nextPrayer);
          _startTimer(nextPrayer);
        } else {
          _loadTomorrowFajr();
        }
      });
    });
  }

  Future<void> _init() async {
    try {
      // Invalidate to get fresh data based on current time
      _ref.invalidate(nextPrayerProvider);
      final nextPrayer = await _ref.read(nextPrayerProvider.future);
      if (nextPrayer != null) {
        _updateState(nextPrayer);
        _startTimer(nextPrayer);
      } else {
        // All prayers passed — show tomorrow's Fajr
        await _loadTomorrowFajr();
      }
    } catch (_) {
      state = const PrayerCountdownState(hasData: false);
    }
  }

  Future<void> _loadTomorrowFajr() async {
    try {
      final position = await _ref.read(locationProvider.future);
      final repo = _ref.read(prayerTimesRepositoryProvider);
      final settings = _ref.read(settingsProvider);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowTimes = repo.getPrayerTimesForDate(
        position.latitude,
        position.longitude,
        tomorrow,
        utcOffset: settings.utcOffset,
      );
      // First prayer (Fajr)
      if (tomorrowTimes.isNotEmpty) {
        final fajr = tomorrowTimes.first;
        _updateState(fajr);
        _startTimer(fajr);
      } else {
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
      if (!mounted) return;
      final now = DateTime.now();
      final remaining = prayer.time.difference(now);
      if (remaining.isNegative) {
        _timer?.cancel();
        // Refresh to get the next prayer
        _ref.invalidate(prayerTimesProvider);
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

// ──────────────────────────────────────────────
// Time-aware Azkar Suggestion Provider
// ──────────────────────────────────────────────
// Picks the azkar category that matches the current moment of the day, using
// real prayer times so it stays correct across seasons and latitudes.

enum AzkarTimeWindow { morning, evening, sleep, wakeUp }

/// Azkar category shown on the home shortcut. Windows (checked in order):
///   Fajr      ≤ now < Asr   → morning (أذكار الصباح)
///   Asr       ≤ now < Isha  → evening (أذكار المساء)
///   Fajr − 2h ≤ now < Fajr  → wakeUp  (أذكار الاستيقاظ من النوم)
///   otherwise (late night)   → sleep   (أذكار النوم)
final azkarTimeWindowProvider = Provider<AzkarTimeWindow>((ref) {
  // Rebuild on hour rollover so the suggestion transitions without requiring
  // a manual refresh (e.g., Isha → sleep, late-night → wakeUp, wakeUp → morning).
  ref.watch(currentHourProvider);

  final prayersAsync = ref.watch(prayerTimesProvider);
  final now = DateTime.now();

  // Sensible defaults in case prayer times haven't loaded yet.
  DateTime fajr = DateTime(now.year, now.month, now.day, 5);
  DateTime asr = DateTime(now.year, now.month, now.day, 15);
  DateTime isha = DateTime(now.year, now.month, now.day, 20);

  prayersAsync.whenData((prayers) {
    for (final p in prayers) {
      switch (p.name) {
        case 'Fajr':
          fajr = p.time;
        case 'Asr':
          asr = p.time;
        case 'Isha':
          isha = p.time;
      }
    }
  });

  final preFajr = fajr.subtract(const Duration(hours: 2));

  if (!now.isBefore(fajr) && now.isBefore(asr)) {
    return AzkarTimeWindow.morning;
  }
  if (!now.isBefore(asr) && now.isBefore(isha)) {
    return AzkarTimeWindow.evening;
  }
  if (!now.isBefore(preFajr) && now.isBefore(fajr)) {
    return AzkarTimeWindow.wakeUp;
  }
  return AzkarTimeWindow.sleep;
});
