import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Available Adhan reciters with their audio URLs.
class AdhanReciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String adhanUrl;
  final String fajrAdhanUrl; // Fajr has a different adhan melody

  const AdhanReciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.adhanUrl,
    String? fajrAdhanUrl,
  }) : fajrAdhanUrl = fajrAdhanUrl ?? adhanUrl;
}

const availableAdhanReciters = [
  AdhanReciter(
    id: 'adhan1',
    nameAr: 'أذان مكة المكرمة',
    nameEn: 'Makkah Adhan',
    adhanUrl: 'https://www.islamcan.com/audio/adhan/azan1.mp3',
    fajrAdhanUrl: 'https://www.islamcan.com/audio/adhan/azan5.mp3',
  ),
  AdhanReciter(
    id: 'adhan2',
    nameAr: 'أذان المدينة المنورة',
    nameEn: 'Madinah Adhan',
    adhanUrl: 'https://www.islamcan.com/audio/adhan/azan2.mp3',
    fajrAdhanUrl: 'https://www.islamcan.com/audio/adhan/azan5.mp3',
  ),
  AdhanReciter(
    id: 'adhan3',
    nameAr: 'أذان المسجد الأقصى',
    nameEn: 'Al-Aqsa Adhan',
    adhanUrl: 'https://www.islamcan.com/audio/adhan/azan3.mp3',
    fajrAdhanUrl: 'https://www.islamcan.com/audio/adhan/azan5.mp3',
  ),
  AdhanReciter(
    id: 'adhan4',
    nameAr: 'الأذان المصري',
    nameEn: 'Egyptian Adhan',
    adhanUrl: 'https://www.islamcan.com/audio/adhan/azan4.mp3',
    fajrAdhanUrl: 'https://www.islamcan.com/audio/adhan/azan5.mp3',
  ),
  AdhanReciter(
    id: 'adhan5',
    nameAr: 'أذان الفجر',
    nameEn: 'Fajr Adhan',
    adhanUrl: 'https://www.islamcan.com/audio/adhan/azan5.mp3',
  ),
  AdhanReciter(
    id: 'adhan6',
    nameAr: 'أذان تركي',
    nameEn: 'Turkish Adhan',
    adhanUrl: 'https://www.islamcan.com/audio/adhan/azan6.mp3',
    fajrAdhanUrl: 'https://www.islamcan.com/audio/adhan/azan5.mp3',
  ),
  AdhanReciter(
    id: 'adhan7',
    nameAr: 'أذان كلاسيكي',
    nameEn: 'Classic Adhan',
    adhanUrl: 'https://www.islamcan.com/audio/adhan/azan7.mp3',
    fajrAdhanUrl: 'https://www.islamcan.com/audio/adhan/azan5.mp3',
  ),
  AdhanReciter(
    id: 'adhan8',
    nameAr: 'أذان خاشع',
    nameEn: 'Soulful Adhan',
    adhanUrl: 'https://www.islamcan.com/audio/adhan/azan8.mp3',
    fajrAdhanUrl: 'https://www.islamcan.com/audio/adhan/azan5.mp3',
  ),
  // ── Sunni adhans from praytimes.org ──
  AdhanReciter(
    id: 'pt_abdul_basit',
    nameAr: 'عبد الباسط',
    nameEn: 'Abdul Basit',
    adhanUrl: 'https://praytimes.org/audio/sunni/Abdul-Basit.mp3',
  ),
  AdhanReciter(
    id: 'pt_abdul_ghaffar',
    nameAr: 'عبد الغفار',
    nameEn: 'Abdul Ghaffar',
    adhanUrl: 'https://praytimes.org/audio/sunni/Abdul-Ghaffar.mp3',
  ),
  AdhanReciter(
    id: 'pt_abdul_hakam',
    nameAr: 'عبد الحكم',
    nameEn: 'Abdul Hakam',
    adhanUrl: 'https://praytimes.org/audio/sunni/Abdul-Hakam.mp3',
  ),
  AdhanReciter(
    id: 'pt_aqsa',
    nameAr: 'أذان المسجد الأقصى',
    nameEn: 'Adhan Al-Aqsa',
    adhanUrl: 'https://praytimes.org/audio/sunni/Adhan-Alaqsa.mp3',
  ),
  AdhanReciter(
    id: 'pt_egypt',
    nameAr: 'أذان مصر',
    nameEn: 'Adhan Egypt',
    adhanUrl: 'https://praytimes.org/audio/sunni/Adhan-Egypt.mp3',
  ),
  AdhanReciter(
    id: 'pt_halab',
    nameAr: 'أذان حلب',
    nameEn: 'Adhan Halab',
    adhanUrl: 'https://praytimes.org/audio/sunni/Adhan-Halab.mp3',
  ),
  AdhanReciter(
    id: 'pt_madinah',
    nameAr: 'أذان المدينة',
    nameEn: 'Adhan Madinah',
    adhanUrl: 'https://praytimes.org/audio/sunni/Adhan-Madinah.mp3',
  ),
  AdhanReciter(
    id: 'pt_mecca',
    nameAr: 'أذان مكة',
    nameEn: 'Adhan Mecca',
    adhanUrl: 'https://praytimes.org/audio/sunni/Adhan-Makkah.mp3',
  ),
  AdhanReciter(
    id: 'pt_hussaini',
    nameAr: 'الحسيني',
    nameEn: 'Al-Hussaini',
    adhanUrl: 'https://praytimes.org/audio/sunni/Al-Hussaini.mp3',
  ),
  AdhanReciter(
    id: 'pt_bakir_bash',
    nameAr: 'بكير باش',
    nameEn: 'Bakir Bash',
    adhanUrl: 'https://praytimes.org/audio/sunni/Bakir-Bash.mp3',
  ),
  AdhanReciter(
    id: 'pt_hafez',
    nameAr: 'حافظ',
    nameEn: 'Hafez',
    adhanUrl: 'https://praytimes.org/audio/sunni/Hafez.mp3',
  ),
  AdhanReciter(
    id: 'pt_hafiz_murad',
    nameAr: 'حافظ مراد',
    nameEn: 'Hafiz Murad',
    adhanUrl: 'https://praytimes.org/audio/sunni/Hafiz-Murad.mp3',
  ),
  AdhanReciter(
    id: 'pt_minshawi',
    nameAr: 'المنشاوي',
    nameEn: 'Minshawi',
    adhanUrl: 'https://praytimes.org/audio/sunni/Minshawi.mp3',
  ),
  AdhanReciter(
    id: 'pt_naghshbandi',
    nameAr: 'النقشبندي',
    nameEn: 'Naghshbandi',
    adhanUrl: 'https://praytimes.org/audio/sunni/Naghshbandi.mp3',
  ),
  AdhanReciter(
    id: 'pt_saber',
    nameAr: 'صابر',
    nameEn: 'Saber',
    adhanUrl: 'https://praytimes.org/audio/sunni/Saber.mp3',
  ),
  AdhanReciter(
    id: 'pt_sharif_doman',
    nameAr: 'شريف دومان',
    nameEn: 'Sharif Doman',
    adhanUrl: 'https://praytimes.org/audio/sunni/Sharif-Doman.mp3',
  ),
  AdhanReciter(
    id: 'pt_yusuf_islam',
    nameAr: 'يوسف إسلام',
    nameEn: 'Yusuf Islam',
    adhanUrl: 'https://praytimes.org/audio/sunni/Yusuf-Islam.mp3',
  ),
];

/// Service for playing Adhan audio at prayer times.
class AdhanAudioService with WidgetsBindingObserver {
  AdhanAudioService._();
  static final AdhanAudioService instance = AdhanAudioService._();

  AudioPlayer? _player;
  bool _lifecycleObserverAttached = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the screen is locked or the app moves off-screen, the lifecycle
    // transitions to inactive/paused/hidden — stop the adhan in any of those.
    if (_player != null && state != AppLifecycleState.resumed) {
      stop();
    }
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
  }

  /// Play the adhan for a given reciter.
  /// [isFajr] uses the special Fajr adhan if available.
  Future<void> playAdhan(String reciterId, {bool isFajr = false}) async {
    await stop(); // Stop any currently playing adhan

    final reciter = availableAdhanReciters.firstWhere(
      (r) => r.id == reciterId,
      orElse: () => availableAdhanReciters.first,
    );

    final url = isFajr ? reciter.fajrAdhanUrl : reciter.adhanUrl;

    final player = AudioPlayer();
    _player = player;
    _attachLifecycleObserver();
    try {
      await _configureAudioSession();
      final duration = await player.setUrl(url);
      if (duration == null) {
        // URL didn't load properly
        await player.dispose();
        _player = null;
        return;
      }
      await player.setVolume(1.0);
      await player.play();

      // Auto-dispose when done
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          stop();
        }
      });
    } catch (e) {
      debugPrint('AdhanAudioService.playAdhan error: $e');
      try {
        await player.dispose();
      } catch (_) {}
      _player = null;
    }
  }

  /// Preview the adhan (for settings screen).
  Future<void> previewAdhan(String reciterId) async {
    await playAdhan(reciterId);
    // Auto-stop after 15 seconds for preview
    Future.delayed(const Duration(seconds: 15), () {
      if (_player != null) {
        stop();
      }
    });
  }

  Future<void> stop() async {
    final player = _player;
    _player = null;
    _detachLifecycleObserver();
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  void _attachLifecycleObserver() {
    if (_lifecycleObserverAttached) return;
    try {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverAttached = true;
    } catch (_) {}
  }

  void _detachLifecycleObserver() {
    if (!_lifecycleObserverAttached) return;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _lifecycleObserverAttached = false;
  }

  bool get isPlaying => _player?.playing ?? false;

  /// Download the selected reciter's adhan MP3 to local cache so it can be
  /// used as a notification sound. Returns the local file path, or null on
  /// failure. Caches by reciter ID — subsequent calls for the same reciter
  /// return the cached file without re-downloading.
  Future<String?> cacheAdhanFile(String reciterId, {bool isFajr = false}) async {
    try {
      final reciter = availableAdhanReciters.firstWhere(
        (r) => r.id == reciterId,
        orElse: () => availableAdhanReciters.first,
      );

      final url = isFajr ? reciter.fajrAdhanUrl : reciter.adhanUrl;
      final suffix = isFajr ? '_fajr' : '';
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/adhan_$reciterId$suffix.mp3');

      if (await file.exists()) return file.path;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file.path;
      }
    } catch (e) {
      debugPrint('AdhanAudioService.cacheAdhanFile error: $e');
    }
    return null;
  }

  /// Clear all cached adhan files (e.g. when reciter changes).
  Future<void> clearCache() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final files = dir.listSync().whereType<File>().where(
          (f) => f.path.contains('adhan_') && f.path.endsWith('.mp3'));
      for (final f in files) {
        await f.delete();
      }
    } catch (_) {}
  }
}
