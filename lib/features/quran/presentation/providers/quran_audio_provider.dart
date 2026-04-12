import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/storage_service.dart';
import 'quran_provider.dart';

/// Reciters with per-ayah audio.
/// Uses cdn.islamic.network for per-ayah audio (128kbps when available, 64kbps fallback).
class Reciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String cdnReciterId; // cdn.islamic.network reciter identifier
  final int bitrate; // available bitrate on CDN (128 or 64)

  const Reciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.cdnReciterId,
    this.bitrate = 128,
  });
}

const availableReciters = [
  Reciter(
    id: 'alafasy',
    nameAr: 'مشاري العفاسي',
    nameEn: 'Mishary Alafasy',
    cdnReciterId: 'ar.alafasy',
  ),
  Reciter(
    id: 'abdulbasit',
    nameAr: 'عبد الباسط عبد الصمد',
    nameEn: 'Abdul Basit',
    cdnReciterId: 'ar.abdulbasitmurattal',
    bitrate: 64,
  ),
  Reciter(
    id: 'husary',
    nameAr: 'محمود خليل الحصري',
    nameEn: 'Al-Husary',
    cdnReciterId: 'ar.husary',
  ),
  Reciter(
    id: 'minshawi',
    nameAr: 'محمد صديق المنشاوي',
    nameEn: 'Al-Minshawi',
    cdnReciterId: 'ar.minshawi',
  ),
  Reciter(
    id: 'sudais',
    nameAr: 'عبد الرحمن السديس',
    nameEn: 'As-Sudais',
    cdnReciterId: 'ar.abdurrahmaansudais',
    bitrate: 64,
  ),
  Reciter(
    id: 'shuraim',
    nameAr: 'سعود الشريم',
    nameEn: 'Ash-Shuraim',
    cdnReciterId: 'ar.saoodshuraym',
    bitrate: 64,
  ),
  Reciter(
    id: 'maher',
    nameAr: 'ماهر المعيقلي',
    nameEn: 'Maher Al-Muaiqly',
    cdnReciterId: 'ar.mahermuaiqly',
  ),
];

/// Info about currently playing ayah for sync highlighting
class PlayingAyahInfo {
  final int surahNumber;
  final int ayahNumber;
  final int globalAyahNumber; // 1-6236, used for audio CDN URL
  final int page;

  const PlayingAyahInfo({
    required this.surahNumber,
    required this.ayahNumber,
    required this.globalAyahNumber,
    required this.page,
  });
}

/// Cumulative ayah counts per surah (surah 1 starts at offset 0).
/// globalAyahNumber = _surahAyahOffset[surahNumber - 1] + ayahNumber
const List<int> _surahAyahOffsets = [
  0, 7, 293, 493, 669, 789, 954, 1160, 1235, 1364, 1473, // 1-10
  1596, 1707, 1750, 1802, 1901, 2029, 2140, 2250, 2348, 2483, // 11-20
  2595, 2673, 2791, 2855, 2932, 3003, 3067, 3159, 3228, 3261, // 21-30
  3295, 3325, 3398, 3452, 3497, 3580, 3662, 3750, 3823, 3898, // 31-40
  3952, 4005, 4094, 4149, 4186, 4221, 4259, 4285, 4303, 4348, // 41-50
  4413, 4462, 4523, 4578, 4655, 4751, 4846, 4868, 4892, 4905, // 51-60
  4919, 4930, 4941, 4959, 4971, 4983, 5013, 5065, 5117, 5161, // 61-70
  5189, 5217, 5237, 5293, 5333, 5364, 5414, 5454, 5500, 5542, // 71-80
  5571, 5590, 5626, 5651, 5673, 5690, 5709, 5735, 5765, 5785, // 81-90
  5800, 5821, 5832, 5840, 5848, 5867, 5872, 5880, 5888, 5896, // 91-100
  5907, 5915, 5918, 5927, 5932, 5937, 5944, 5947, 5953, 5956, // 101-110
  5959, 5963, 5968, 5973, // 111-114
];

int _getGlobalAyahNumber(int surahNumber, int ayahNumber) {
  if (surahNumber < 1 || surahNumber > 114) return ayahNumber;
  return _surahAyahOffsets[surahNumber - 1] + ayahNumber;
}

/// State for the Quran audio player
class QuranAudioState {
  final bool isPlaying;
  final bool isLoading;
  final int? currentSurah;
  final int? currentAyahIndex; // index in the playlist
  final int totalAyahs;
  final String reciterId;
  final Duration position;
  final Duration duration;
  final String? error;
  final PlayingAyahInfo? playingAyah; // currently playing ayah for highlighting

  const QuranAudioState({
    this.isPlaying = false,
    this.isLoading = false,
    this.currentSurah,
    this.currentAyahIndex,
    this.totalAyahs = 0,
    this.reciterId = 'alafasy',
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
    this.playingAyah,
  });

  Reciter get reciter =>
      availableReciters.firstWhere((r) => r.id == reciterId,
          orElse: () => availableReciters.first);

  QuranAudioState copyWith({
    bool? isPlaying,
    bool? isLoading,
    int? currentSurah,
    int? currentAyahIndex,
    int? totalAyahs,
    String? reciterId,
    Duration? position,
    Duration? duration,
    String? error,
    PlayingAyahInfo? playingAyah,
    bool clearError = false,
    bool clearSurah = false,
    bool clearAyah = false,
  }) {
    return QuranAudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentSurah: clearSurah ? null : (currentSurah ?? this.currentSurah),
      currentAyahIndex: clearAyah ? null : (currentAyahIndex ?? this.currentAyahIndex),
      totalAyahs: totalAyahs ?? this.totalAyahs,
      reciterId: reciterId ?? this.reciterId,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
      playingAyah: clearAyah ? null : (playingAyah ?? this.playingAyah),
    );
  }
}

class QuranAudioNotifier extends StateNotifier<QuranAudioState> {
  final AudioPlayer _player;
  final StorageService _storage;
  final Ref _ref;

  /// Ayah metadata for the current playlist (surah, ayahNumber, page)
  List<PlayingAyahInfo> _ayahPlaylist = [];
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  QuranAudioNotifier(this._storage, this._ref)
      : _player = AudioPlayer(),
        super(const QuranAudioState()) {
    _init();
  }

  void _init() {
    final savedReciter =
        _storage.getSetting<String>('reciterId', defaultValue: 'alafasy') ??
            'alafasy';
    state = state.copyWith(reciterId: savedReciter);

    _stateSub = _player.playerStateStream.listen((playerState) {
      if (!mounted) return;
      state = state.copyWith(
        isPlaying: playerState.playing,
        isLoading: playerState.processingState == ProcessingState.loading ||
            playerState.processingState == ProcessingState.buffering,
      );

      if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(
          isPlaying: false,
          position: Duration.zero,
          clearAyah: true,
        );
        // Clear the highlight when done
        _ref.read(highlightedAyahProvider.notifier).clearHighlight();
      }
    });

    _posSub = _player.positionStream.listen((pos) {
      if (!mounted) return;
      state = state.copyWith(position: pos);
    });

    _durSub = _player.durationStream.listen((dur) {
      if (!mounted) return;
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });

    // Listen to current index changes for ayah-by-ayah highlighting
    _indexSub = _player.currentIndexStream.listen((index) {
      if (!mounted || index == null) return;
      if (index < _ayahPlaylist.length) {
        final ayahInfo = _ayahPlaylist[index];
        state = state.copyWith(
          currentAyahIndex: index,
          playingAyah: ayahInfo,
        );
        // Sync highlight with the playing ayah
        _ref.read(highlightedAyahProvider.notifier).setHighlight(
              ayahInfo.surahNumber,
              ayahInfo.ayahNumber,
              ayahInfo.page,
            );
      }
    });
  }

  /// Build per-ayah URL from cdn.islamic.network.
  String _getAyahUrl(int globalAyahNumber) {
    final reciter = state.reciter;
    return 'https://cdn.islamic.network/quran/audio/${reciter.bitrate}/${reciter.cdnReciterId}/$globalAyahNumber.mp3';
  }

  /// Play a surah ayah-by-ayah with sync highlighting.
  /// [startFromAyah] optionally starts from a specific ayah number instead of the first.
  Future<void> playSurah(int surahNumber, {int? startFromAyah}) async {
    try {
      state = state.copyWith(
        isLoading: true,
        currentSurah: surahNumber,
        clearError: true,
        clearAyah: true,
        position: Duration.zero,
        duration: Duration.zero,
      );

      // Get ayah count and page info from quran data
      final pageIndex = await _ref.read(pageIndexProvider.future);
      final ayahInfoList = <PlayingAyahInfo>[];

      // Scan all pages to find ayahs for this surah
      for (int p = 1; p <= 604; p++) {
        final page = pageIndex[p];
        if (page == null) continue;
        for (final section in page.sections) {
          if (section.surahNumber == surahNumber) {
            for (final ayah in section.ayahs) {
              ayahInfoList.add(PlayingAyahInfo(
                surahNumber: surahNumber,
                ayahNumber: ayah.ayahNumber,
                globalAyahNumber: _getGlobalAyahNumber(surahNumber, ayah.ayahNumber),
                page: p,
              ));
            }
          }
        }
      }

      if (ayahInfoList.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'لم يتم العثور على آيات السورة',
        );
        return;
      }

      _ayahPlaylist = ayahInfoList;

      // Find the starting index if a specific ayah was requested
      int initialIndex = 0;
      if (startFromAyah != null) {
        final idx = ayahInfoList.indexWhere(
            (a) => a.ayahNumber == startFromAyah);
        if (idx >= 0) {
          initialIndex = idx;
        }
      }

      // Build a playlist of audio sources
      final sources = ayahInfoList.map((info) {
        return AudioSource.uri(
          Uri.parse(_getAyahUrl(info.globalAyahNumber)),
        );
      }).toList();

      final playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(playlist, initialIndex: initialIndex);

      state = state.copyWith(
        totalAyahs: ayahInfoList.length,
        isLoading: false,
      );

      await _player.play();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: 'فشل تشغيل السورة. تأكد من اتصال الإنترنت.',
      );
    }
  }

  /// Play from a specific ayah within a surah
  Future<void> playFromAyah(int surahNumber, int ayahNumber) async {
    // If already playing this surah, just seek to the ayah
    if (state.currentSurah == surahNumber && _ayahPlaylist.isNotEmpty) {
      final index = _ayahPlaylist.indexWhere(
          (a) => a.surahNumber == surahNumber && a.ayahNumber == ayahNumber);
      if (index >= 0) {
        await _player.seek(Duration.zero, index: index);
        if (!state.isPlaying) {
          await _player.play();
        }
        return;
      }
    }
    // Load the surah starting directly from the requested ayah
    await playSurah(surahNumber, startFromAyah: ayahNumber);
  }

  /// Skip to next ayah
  Future<void> nextAyah() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  /// Skip to previous ayah
  Future<void> previousAyah() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _ayahPlaylist = [];
    state = state.copyWith(
      isPlaying: false,
      clearSurah: true,
      clearAyah: true,
      position: Duration.zero,
      duration: Duration.zero,
      totalAyahs: 0,
    );
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setReciter(String reciterId) async {
    final hadAudio = state.currentSurah != null;
    final wasPlaying = state.isPlaying;
    final currentSurah = state.currentSurah;
    // Get the current ayah number (not index) for accurate resume
    final currentAyahNumber = state.playingAyah?.ayahNumber;

    await _player.stop();
    _ayahPlaylist = [];
    state = state.copyWith(reciterId: reciterId, clearAyah: true);
    await _storage.putSetting('reciterId', reciterId);

    // Resume from the same ayah with the new reciter (whether playing or paused)
    if (hadAudio && currentSurah != null) {
      await playSurah(currentSurah, startFromAyah: currentAyahNumber);
      if (!wasPlaying) {
        await _player.pause();
      }
    }
  }

  @override
  void dispose() {
    _indexSub?.cancel();
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final quranAudioProvider =
    StateNotifierProvider<QuranAudioNotifier, QuranAudioState>((ref) {
  return QuranAudioNotifier(StorageService.instance, ref);
});
