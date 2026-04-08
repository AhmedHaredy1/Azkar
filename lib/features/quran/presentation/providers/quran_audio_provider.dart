import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/storage_service.dart';
import 'quran_provider.dart';

/// Reciters with per-ayah audio from everyayah.com
class Reciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String ayahFolder; // everyayah.com folder for per-ayah files
  final String surahBaseUrl; // mp3quran.net for full surah fallback

  const Reciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.ayahFolder,
    required this.surahBaseUrl,
  });
}

const availableReciters = [
  Reciter(
    id: 'alafasy',
    nameAr: 'مشاري العفاسي',
    nameEn: 'Mishary Alafasy',
    ayahFolder: 'Alafasy_128kbps',
    surahBaseUrl: 'https://server8.mp3quran.net/afs',
  ),
  Reciter(
    id: 'abdulbasit',
    nameAr: 'عبد الباسط عبد الصمد',
    nameEn: 'Abdul Basit',
    ayahFolder: 'Abdul_Basit_Murattal_192kbps',
    surahBaseUrl: 'https://server7.mp3quran.net/basit',
  ),
  Reciter(
    id: 'husary',
    nameAr: 'محمود خليل الحصري',
    nameEn: 'Al-Husary',
    ayahFolder: 'Husary_128kbps',
    surahBaseUrl: 'https://server13.mp3quran.net/husr',
  ),
  Reciter(
    id: 'minshawi',
    nameAr: 'محمد صديق المنشاوي',
    nameEn: 'Al-Minshawi',
    ayahFolder: 'Minshawy_Murattal_128kbps',
    surahBaseUrl: 'https://server10.mp3quran.net/minsh',
  ),
  Reciter(
    id: 'sudais',
    nameAr: 'عبد الرحمن السديس',
    nameEn: 'As-Sudais',
    ayahFolder: 'Abdurrahmaan_As-Sudais_192kbps',
    surahBaseUrl: 'https://server11.mp3quran.net/sds',
  ),
  Reciter(
    id: 'shuraim',
    nameAr: 'سعود الشريم',
    nameEn: 'Ash-Shuraim',
    ayahFolder: 'Saood_ash-Shuraym_128kbps',
    surahBaseUrl: 'https://server7.mp3quran.net/shur',
  ),
  Reciter(
    id: 'maher',
    nameAr: 'ماهر المعيقلي',
    nameEn: 'Maher Al-Muaiqly',
    ayahFolder: 'MauroAyah',
    surahBaseUrl: 'https://server12.mp3quran.net/maher',
  ),
];

/// Info about currently playing ayah for sync highlighting
class PlayingAyahInfo {
  final int surahNumber;
  final int ayahNumber;
  final int page;

  const PlayingAyahInfo({
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
  });
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

  /// Build per-ayah URL from everyayah.com
  String _getAyahUrl(int surahNumber, int ayahNumber) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/${state.reciter.ayahFolder}/$surah$ayah.mp3';
  }

  /// Play a surah ayah-by-ayah with sync highlighting
  Future<void> playSurah(int surahNumber) async {
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

      // Build a playlist of audio sources
      final sources = ayahInfoList.map((info) {
        return AudioSource.uri(
          Uri.parse(_getAyahUrl(info.surahNumber, info.ayahNumber)),
        );
      }).toList();

      final playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(playlist);

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
    // Otherwise, load the surah and seek
    await playSurah(surahNumber);
    // Wait a moment for playlist to load, then seek
    await Future.delayed(const Duration(milliseconds: 500));
    if (_ayahPlaylist.isNotEmpty) {
      final index = _ayahPlaylist.indexWhere(
          (a) => a.surahNumber == surahNumber && a.ayahNumber == ayahNumber);
      if (index > 0) {
        await _player.seek(Duration.zero, index: index);
      }
    }
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
    final wasPlaying = state.isPlaying;
    final currentSurah = state.currentSurah;
    final currentIndex = state.currentAyahIndex;

    await _player.stop();
    _ayahPlaylist = [];
    state = state.copyWith(reciterId: reciterId, clearAyah: true);
    await _storage.putSetting('reciterId', reciterId);

    // Restart with new reciter from same position
    if (wasPlaying && currentSurah != null) {
      await playSurah(currentSurah);
      if (currentIndex != null && currentIndex > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_ayahPlaylist.isNotEmpty && currentIndex < _ayahPlaylist.length) {
          await _player.seek(Duration.zero, index: currentIndex);
        }
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
