import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../../core/services/global_audio_handler.dart';
import '../../../../core/services/storage_service.dart';
import '../../../live_radio/presentation/providers/live_radio_provider.dart';
import '../../../quran/presentation/providers/quran_audio_provider.dart';
import '../../data/mp3quran_api.dart';
import '../../domain/models/mp3quran_reciter.dart';

// ──────────────────────────────────────────────
// API & Data Providers
// ──────────────────────────────────────────────

final mp3QuranApiProvider = Provider<Mp3QuranApi>((ref) {
  return Mp3QuranApi(StorageService.instance);
});

final mp3QuranRecitersProvider =
    FutureProvider<List<Mp3QuranReciter>>((ref) async {
  final api = ref.read(mp3QuranApiProvider);
  return api.getReciters();
});

/// All unique moshaf types found across all reciters.
final availableMoshafTypesProvider = FutureProvider<List<int>>((ref) async {
  final reciters = await ref.watch(mp3QuranRecitersProvider.future);
  final types = <int>{};
  for (final r in reciters) {
    for (final m in r.moshaf) {
      types.add(m.moshafType);
    }
  }
  final sorted = types.toList()..sort();
  return sorted;
});

// ──────────────────────────────────────────────
// Filter State
// ──────────────────────────────────────────────

class ListenFilterState {
  final int selectedSurah; // 1-114
  final int? selectedMoshafType; // null = all types

  const ListenFilterState({
    this.selectedSurah = 1,
    this.selectedMoshafType,
  });

  ListenFilterState copyWith({
    int? selectedSurah,
    int? selectedMoshafType,
    bool clearMoshafType = false,
  }) {
    return ListenFilterState(
      selectedSurah: selectedSurah ?? this.selectedSurah,
      selectedMoshafType:
          clearMoshafType ? null : (selectedMoshafType ?? this.selectedMoshafType),
    );
  }
}

class ListenFilterNotifier extends StateNotifier<ListenFilterState> {
  ListenFilterNotifier() : super(const ListenFilterState());

  void setSurah(int surah) => state = state.copyWith(selectedSurah: surah);

  void setMoshafType(int? type) {
    if (type == null) {
      state = state.copyWith(clearMoshafType: true);
    } else {
      state = state.copyWith(selectedMoshafType: type);
    }
  }
}

final listenFilterProvider =
    StateNotifierProvider<ListenFilterNotifier, ListenFilterState>((ref) {
  return ListenFilterNotifier();
});

// ──────────────────────────────────────────────
// Filtered Reciters
// ──────────────────────────────────────────────

/// A reciter+moshaf pair that has the selected surah.
class ReciterWithMoshaf {
  final Mp3QuranReciter reciter;
  final Mp3QuranMoshaf moshaf;

  const ReciterWithMoshaf({required this.reciter, required this.moshaf});

  String get audioUrl => moshaf.getAudioUrl(0); // placeholder
  String getAudioUrlForSurah(int surah) => moshaf.getAudioUrl(surah);
}

final filteredRecitersProvider =
    FutureProvider<List<ReciterWithMoshaf>>((ref) async {
  final reciters = await ref.watch(mp3QuranRecitersProvider.future);
  final filter = ref.watch(listenFilterProvider);

  final results = <ReciterWithMoshaf>[];
  for (final r in reciters) {
    for (final m in r.moshaf) {
      if (!m.hasSurah(filter.selectedSurah)) continue;
      if (filter.selectedMoshafType != null &&
          m.moshafType != filter.selectedMoshafType) {
        continue;
      }
      results.add(ReciterWithMoshaf(reciter: r, moshaf: m));
    }
  }

  // Sort by reciter name
  results.sort((a, b) => a.reciter.name.compareTo(b.reciter.name));
  return results;
});

/// Moshaf types available for the currently selected surah.
final moshafTypesForSurahProvider = FutureProvider<List<int>>((ref) async {
  final reciters = await ref.watch(mp3QuranRecitersProvider.future);
  final filter = ref.watch(listenFilterProvider);

  final types = <int>{};
  for (final r in reciters) {
    for (final m in r.moshaf) {
      if (m.hasSurah(filter.selectedSurah)) {
        types.add(m.moshafType);
      }
    }
  }
  final sorted = types.toList()..sort();
  return sorted;
});

// ──────────────────────────────────────────────
// Audio Player State
// ──────────────────────────────────────────────

class ListenPlayerState {
  final bool isPlaying;
  final bool isLoading;
  final String? reciterName;
  final String? moshafName;
  final int? surahNumber;
  final Duration position;
  final Duration duration;
  final String? error;

  const ListenPlayerState({
    this.isPlaying = false,
    this.isLoading = false,
    this.reciterName,
    this.moshafName,
    this.surahNumber,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  bool get hasAudio => surahNumber != null;

  ListenPlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    String? reciterName,
    String? moshafName,
    int? surahNumber,
    Duration? position,
    Duration? duration,
    String? error,
    bool clearError = false,
    bool clearAudio = false,
  }) {
    return ListenPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      reciterName: clearAudio ? null : (reciterName ?? this.reciterName),
      moshafName: clearAudio ? null : (moshafName ?? this.moshafName),
      surahNumber: clearAudio ? null : (surahNumber ?? this.surahNumber),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ListenPlayerNotifier extends StateNotifier<ListenPlayerState> {
  final AudioPlayer _player = AudioPlayer();
  final Ref _ref;
  ReciterWithMoshaf? _currentRwm;

  ListenPlayerNotifier(this._ref) : super(const ListenPlayerState()) {
    _configureAudioSession();
    _player.playerStateStream.listen((ps) {
      if (!mounted) return;
      state = state.copyWith(
        isPlaying: ps.playing,
        isLoading: ps.processingState == ProcessingState.loading ||
            ps.processingState == ProcessingState.buffering,
      );
      if (ps.processingState == ProcessingState.completed) {
        state = state.copyWith(
          isPlaying: false,
          position: Duration.zero,
        );
        // Auto-continue to next surah
        _playNextSurah();
      }
    });

    _player.positionStream.listen((pos) {
      if (!mounted) return;
      state = state.copyWith(position: pos);
    });

    _player.durationStream.listen((dur) {
      if (!mounted) return;
      if (dur != null) state = state.copyWith(duration: dur);
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

  void _stopOtherPlayers() {
    try {
      _ref.read(quranAudioProvider.notifier).stop();
    } catch (_) {}
    try {
      _ref.read(liveRadioProvider.notifier).stop();
    } catch (_) {}
  }

  void _attachToHandler({required String title, String? subtitle}) {
    try {
      final handler = _ref.read(globalAudioHandlerProvider);
      handler.attachPlayer(_player, ActiveAudioSource.quranListen,
          title: title, subtitle: subtitle);
    } catch (_) {}
  }

  void _detachFromHandler() {
    try {
      final handler = _ref.read(globalAudioHandlerProvider);
      if (handler.activeSource == ActiveAudioSource.quranListen) {
        handler.detachPlayer();
      }
    } catch (_) {}
  }

  Future<void> play(ReciterWithMoshaf rwm, int surahNumber) async {
    try {
      _stopOtherPlayers();
      _currentRwm = rwm;
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        reciterName: rwm.reciter.name,
        moshafName: rwm.moshaf.name,
        surahNumber: surahNumber,
        position: Duration.zero,
        duration: Duration.zero,
      );

      final url = rwm.getAudioUrlForSurah(surahNumber);
      await _player.setUrl(url);

      // Get surah name for notification
      String surahName = 'سورة $surahNumber';
      try {
        final names = await _ref.read(surahNamesProvider.future);
        if (names.containsKey(surahNumber)) {
          surahName = 'سورة ${names[surahNumber]}';
        }
      } catch (_) {}

      _attachToHandler(
        title: surahName,
        subtitle: rwm.reciter.name,
      );

      await _player.play();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: 'فشل تشغيل السورة. تأكد من اتصال الإنترنت.',
      );
    }
  }

  Future<void> _playNextSurah() async {
    final rwm = _currentRwm;
    final currentSurah = state.surahNumber;
    if (rwm == null || currentSurah == null || currentSurah >= 114) return;

    final nextSurah = currentSurah + 1;
    if (rwm.moshaf.hasSurah(nextSurah)) {
      await play(rwm, nextSurah);
    }
  }

  /// Manually skip to the next surah available in the current reciter's moshaf.
  Future<void> nextSurah() async {
    final rwm = _currentRwm;
    final currentSurah = state.surahNumber;
    if (rwm == null || currentSurah == null) return;
    for (int n = currentSurah + 1; n <= 114; n++) {
      if (rwm.moshaf.hasSurah(n)) {
        await play(rwm, n);
        return;
      }
    }
  }

  /// Manually skip to the previous surah available in the current reciter's moshaf.
  Future<void> previousSurah() async {
    final rwm = _currentRwm;
    final currentSurah = state.surahNumber;
    if (rwm == null || currentSurah == null) return;
    for (int n = currentSurah - 1; n >= 1; n--) {
      if (rwm.moshaf.hasSurah(n)) {
        await play(rwm, n);
        return;
      }
    }
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async => _player.play();

  Future<void> stop() async {
    await _player.stop();
    _detachFromHandler();
    _currentRwm = null;
    state = state.copyWith(
      isPlaying: false,
      clearAudio: true,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }

  Future<void> seekTo(Duration pos) async => _player.seek(pos);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final listenPlayerProvider =
    StateNotifierProvider<ListenPlayerNotifier, ListenPlayerState>((ref) {
  return ListenPlayerNotifier(ref);
});

// ──────────────────────────────────────────────
// Surah names provider (reuse from Quran feature)
// ──────────────────────────────────────────────

final surahNamesProvider = FutureProvider<Map<int, String>>((ref) async {
  // Use the canonical, non-inflected Arabic surah names — the names in
  // quran.json carry case-ending diacritics (e.g., "ٱلْفَاتِحَةِ") which
  // read awkwardly in dropdowns and player labels.
  return kSurahNamesAr;
});
