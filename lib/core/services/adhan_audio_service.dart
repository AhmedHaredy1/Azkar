import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

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
];

/// Service for playing Adhan audio at prayer times.
class AdhanAudioService {
  AdhanAudioService._();
  static final AdhanAudioService instance = AdhanAudioService._();

  AudioPlayer? _player;

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
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  bool get isPlaying => _player?.playing ?? false;
}
