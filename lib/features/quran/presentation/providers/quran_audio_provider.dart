import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../../core/services/global_audio_handler.dart';
import '../../../../core/services/storage_service.dart';
import '../../../live_radio/presentation/providers/live_radio_provider.dart';
import '../../../quran_listen/presentation/providers/quran_listen_provider.dart';
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
  final bool isBismillah; // audio-only Bismillah that precedes a surah

  const PlayingAyahInfo({
    required this.surahNumber,
    required this.ayahNumber,
    required this.globalAyahNumber,
    required this.page,
    this.isBismillah = false,
  });
}

/// Starting global-ayah offset for each surah (surah 1 starts at offset 0).
/// globalAyahNumber = _surahAyahOffsets[surahNumber - 1] + ayahNumber.
/// Derived from the Hafs mushaf ayah counts; total ayahs = 6236.
const List<int> _surahAyahOffsets = [
  0, 7, 293, 493, 669, 789, 954, 1160, 1235, 1364, // surahs 1-10
  1473, 1596, 1707, 1750, 1802, 1901, 2029, 2140, 2250, 2348, // 11-20
  2483, 2595, 2673, 2791, 2855, 2932, 3159, 3252, 3340, 3409, // 21-30
  3469, 3503, 3533, 3606, 3660, 3705, 3788, 3970, 4058, 4133, // 31-40
  4218, 4272, 4325, 4414, 4473, 4510, 4545, 4583, 4612, 4630, // 41-50
  4675, 4735, 4784, 4846, 4901, 4979, 5075, 5104, 5126, 5150, // 51-60
  5163, 5177, 5188, 5199, 5217, 5229, 5241, 5271, 5323, 5375, // 61-70
  5419, 5447, 5475, 5495, 5551, 5591, 5622, 5672, 5712, 5758, // 71-80
  5800, 5829, 5848, 5884, 5909, 5931, 5948, 5967, 5993, 6023, // 81-90
  6043, 6058, 6079, 6090, 6098, 6106, 6125, 6130, 6138, 6146, // 91-100
  6157, 6168, 6176, 6179, 6188, 6193, 6197, 6204, 6207, 6213, // 101-110
  6216, 6221, 6225, 6230, // 111-114
];

/// Maps a (surah, ayah) pair to the 1-based global ayah index used by
/// cdn.islamic.network audio URLs. Out-of-range surahs fall back to the
/// raw ayah number so callers never crash on bad input.
int getGlobalAyahNumber(int surahNumber, int ayahNumber) {
  if (surahNumber < 1 || surahNumber > 114) return ayahNumber;
  return _surahAyahOffsets[surahNumber - 1] + ayahNumber;
}

/// surah number → its ayahs in mushaf order, each carrying its page number.
/// Built in a single pass over the page index and cached, so [playSurah]
/// does an O(1) lookup instead of rescanning all 604 pages on every play.
final surahAudioIndexProvider =
    FutureProvider<Map<int, List<PlayingAyahInfo>>>((ref) async {
  final pageIndex = await ref.watch(pageIndexProvider.future);
  final index = <int, List<PlayingAyahInfo>>{};
  final pages = pageIndex.keys.toList()..sort();
  for (final p in pages) {
    for (final section in pageIndex[p]!.sections) {
      final list = index.putIfAbsent(section.surahNumber, () => []);
      for (final ayah in section.ayahs) {
        list.add(PlayingAyahInfo(
          surahNumber: section.surahNumber,
          ayahNumber: ayah.ayahNumber,
          globalAyahNumber:
              getGlobalAyahNumber(section.surahNumber, ayah.ayahNumber),
          page: p,
        ));
      }
    }
  }
  return index;
});

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
      : _player = AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [],
          ),
        ),
        super(const QuranAudioState()) {
    _init();
  }

  void _init() {
    final savedReciter =
        _storage.getSetting<String>('reciterId', defaultValue: 'alafasy') ??
            'alafasy';
    state = state.copyWith(reciterId: savedReciter);

    // Configure audio session for high-quality music playback
    _configureAudioSession();

    _stateSub = _player.playerStateStream.listen((playerState) {
      if (!mounted) return;
      state = state.copyWith(
        isPlaying: playerState.playing,
        isLoading: playerState.processingState == ProcessingState.loading ||
            playerState.processingState == ProcessingState.buffering,
      );

      if (playerState.processingState == ProcessingState.completed) {
        final currentSurah = state.currentSurah;
        state = state.copyWith(
          isPlaying: false,
          position: Duration.zero,
          clearAyah: true,
        );
        _ref.read(highlightedAyahProvider.notifier).clearHighlight();

        // Auto-continue to next surah
        if (currentSurah != null && currentSurah < 114) {
          playSurah(currentSurah + 1);
        }
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
        // During the Bismillah track, clear the ayah highlight — the Bismillah
        // header itself is the visual cue, not ayah 1.
        if (ayahInfo.isBismillah) {
          _ref.read(highlightedAyahProvider.notifier).clearHighlight();
        } else {
          _ref.read(highlightedAyahProvider.notifier).setHighlight(
                ayahInfo.surahNumber,
                ayahInfo.ayahNumber,
                ayahInfo.page,
              );
        }
      }
    });
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

  /// Build per-ayah URL from cdn.islamic.network.
  String _getAyahUrl(int globalAyahNumber) {
    final reciter = state.reciter;
    return 'https://cdn.islamic.network/quran/audio/${reciter.bitrate}/${reciter.cdnReciterId}/$globalAyahNumber.mp3';
  }

  /// Stop other audio sources for mutual exclusivity.
  void _stopOtherPlayers() {
    try {
      _ref.read(listenPlayerProvider.notifier).stop();
    } catch (_) {}
    try {
      _ref.read(liveRadioProvider.notifier).stop();
    } catch (_) {}
  }

  /// Attach to the global audio handler for lock screen / notification controls.
  void _attachToHandler({required String title, String? subtitle}) {
    try {
      final handler = _ref.read(globalAudioHandlerProvider);
      handler.attachPlayer(_player, ActiveAudioSource.quranAyah,
          title: title, subtitle: subtitle);
    } catch (_) {}
  }

  /// Detach from the global audio handler.
  void _detachFromHandler() {
    try {
      final handler = _ref.read(globalAudioHandlerProvider);
      if (handler.activeSource == ActiveAudioSource.quranAyah) {
        handler.detachPlayer();
      }
    } catch (_) {}
  }

  /// Play a surah ayah-by-ayah with sync highlighting.
  /// [startFromAyah] optionally starts from a specific ayah number instead of the first.
  Future<void> playSurah(int surahNumber, {int? startFromAyah}) async {
    try {
      _stopOtherPlayers();

      state = state.copyWith(
        isLoading: true,
        currentSurah: surahNumber,
        clearError: true,
        clearAyah: true,
        position: Duration.zero,
        duration: Duration.zero,
      );

      // O(1) lookup in the cached surah → ayahs index. Copy the list:
      // the Bismillah insert below must not mutate the shared cache.
      final surahIndex = await _ref.read(surahAudioIndexProvider.future);
      final ayahInfoList =
          List<PlayingAyahInfo>.of(surahIndex[surahNumber] ?? const []);

      if (ayahInfoList.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'لم يتم العثور على آيات السورة',
        );
        return;
      }

      // Prepend Bismillah before the surah when starting from the beginning.
      // Al-Fatihah's own ayah 1 IS Bismillah, and At-Tawbah has no Bismillah.
      final startsAtBeginning = startFromAyah == null || startFromAyah == 1;
      final needsBismillah =
          startsAtBeginning && surahNumber != 1 && surahNumber != 9;
      if (needsBismillah) {
        ayahInfoList.insert(
          0,
          PlayingAyahInfo(
            surahNumber: surahNumber,
            ayahNumber: 1,
            // cdn.islamic.network global ayah 1 = Al-Fatihah ayah 1 = Bismillah
            globalAyahNumber: 1,
            page: ayahInfoList.first.page,
            isBismillah: true,
          ),
        );
      }

      _ayahPlaylist = ayahInfoList;

      // Find the starting index if a specific ayah was requested
      int initialIndex = 0;
      if (startFromAyah != null && startFromAyah != 1) {
        final idx = ayahInfoList.indexWhere(
            (a) => !a.isBismillah && a.ayahNumber == startFromAyah);
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

      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: false,
        children: sources,
      );
      await _player.setAudioSource(playlist, initialIndex: initialIndex);

      state = state.copyWith(
        // Exclude the prepended Bismillah from the displayed ayah count.
        totalAyahs: ayahInfoList.where((a) => !a.isBismillah).length,
        isLoading: false,
      );

      // Surah name for the lock-screen notification — constant-time lookup.
      final surahName = 'سورة ${kSurahNamesAr[surahNumber] ?? surahNumber}';

      _attachToHandler(
        title: surahName,
        subtitle: state.reciter.nameAr,
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
    _detachFromHandler();
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
  return QuranAudioNotifier(ref.watch(storageServiceProvider), ref);
});
