import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/services/global_audio_handler.dart';
import '../../../live_radio/presentation/providers/live_radio_provider.dart';
import '../../../quran/presentation/providers/quran_audio_provider.dart';
import '../../../quran_downloads/presentation/providers/downloads_provider.dart';
import '../../data/mp3quran_api.dart';
import '../../domain/models/mp3quran_reciter.dart';

// ──────────────────────────────────────────────
// API & Data Providers
// ──────────────────────────────────────────────

final mp3QuranApiProvider = Provider<Mp3QuranApi>((ref) {
  return Mp3QuranApi(ref.watch(storageServiceProvider));
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
  final bool downloadedOnly;

  const ListenFilterState({
    this.selectedSurah = 1,
    this.selectedMoshafType,
    this.downloadedOnly = false,
  });

  ListenFilterState copyWith({
    int? selectedSurah,
    int? selectedMoshafType,
    bool? downloadedOnly,
    bool clearMoshafType = false,
  }) {
    return ListenFilterState(
      selectedSurah: selectedSurah ?? this.selectedSurah,
      selectedMoshafType:
          clearMoshafType ? null : (selectedMoshafType ?? this.selectedMoshafType),
      downloadedOnly: downloadedOnly ?? this.downloadedOnly,
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

  void setDownloadedOnly(bool value) =>
      state = state.copyWith(downloadedOnly: value);
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
  // Watch downloaded keys so the list re-filters as files are added/removed.
  final downloadedKeys = ref.watch(
    downloadsProvider.select((s) => s.downloadedKeys),
  );

  final results = <ReciterWithMoshaf>[];
  for (final r in reciters) {
    for (final m in r.moshaf) {
      if (!m.hasSurah(filter.selectedSurah)) continue;
      if (filter.selectedMoshafType != null &&
          m.moshafType != filter.selectedMoshafType) {
        continue;
      }
      if (filter.downloadedOnly) {
        final key = '${r.id}_${m.id}_${filter.selectedSurah}';
        if (!downloadedKeys.contains(key)) continue;
      }
      results.add(ReciterWithMoshaf(reciter: r, moshaf: m));
    }
  }

  // Sort by reciter name
  results.sort((a, b) => a.reciter.name.compareTo(b.reciter.name));
  return results;
});

/// True when the user has at least one downloaded surah (any reciter).
final hasAnyDownloadedProvider = Provider<bool>((ref) {
  final keys = ref.watch(downloadsProvider.select((s) => s.downloadedKeys));
  return keys.isNotEmpty;
});

/// A single entry in the offline playlist — one surah from one reciter.
class PlaylistItem {
  final int reciterId;
  final int moshafId;
  final int surahNumber;
  final String reciterName;
  final String moshafName;
  final String filePath;
  const PlaylistItem({
    required this.reciterId,
    required this.moshafId,
    required this.surahNumber,
    required this.reciterName,
    required this.moshafName,
    required this.filePath,
  });
  String get key => '${reciterId}_${moshafId}_$surahNumber';
}

/// Playlist of every downloaded surah, sorted by surah number (1 → 114).
/// Different surahs may come from different reciters — the sort is by surah
/// so continuous playback follows the Qur'an's order.
final downloadedPlaylistProvider =
    FutureProvider<List<PlaylistItem>>((ref) async {
  final reciters = await ref.watch(mp3QuranRecitersProvider.future);
  final keys = ref.watch(downloadsProvider.select((s) => s.downloadedKeys));
  if (keys.isEmpty) return const [];

  final items = <PlaylistItem>[];
  for (final key in keys) {
    final parts = key.split('_');
    if (parts.length != 3) continue;
    final rid = int.tryParse(parts[0]);
    final mid = int.tryParse(parts[1]);
    final surah = int.tryParse(parts[2]);
    if (rid == null || mid == null || surah == null) continue;

    Mp3QuranReciter? reciter;
    for (final r in reciters) {
      if (r.id == rid) {
        reciter = r;
        break;
      }
    }
    if (reciter == null) continue;

    Mp3QuranMoshaf? moshaf;
    for (final m in reciter.moshaf) {
      if (m.id == mid) {
        moshaf = m;
        break;
      }
    }
    if (moshaf == null) continue;

    final file =
        await ref.read(surahDownloadServiceProvider).trackFile(rid, mid, surah);
    items.add(PlaylistItem(
      reciterId: rid,
      moshafId: mid,
      surahNumber: surah,
      reciterName: reciter.name,
      moshafName: moshaf.name,
      filePath: file.path,
    ));
  }

  items.sort((a, b) {
    final c = a.surahNumber.compareTo(b.surahNumber);
    if (c != 0) return c;
    return a.reciterName.compareTo(b.reciterName);
  });
  return items;
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
  List<PlaylistItem>? _playlist;
  int _playlistIndex = 0;

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
      // Starting a single-surah playback exits playlist mode.
      _playlist = null;
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
      // Prefer the offline copy when available; fall back to streaming.
      final offline = await _ref
          .read(surahDownloadServiceProvider)
          .trackFile(rwm.reciter.id, rwm.moshaf.id, surahNumber);
      if (offline.existsSync()) {
        await _player.setFilePath(offline.path);
      } else {
        await _player.setUrl(url);
      }

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
    // Playlist mode takes precedence — advance to the next entry.
    if (_playlist != null) {
      final items = _playlist!;
      if (_playlistIndex + 1 < items.length) {
        _playlistIndex += 1;
        await _playPlaylistItem(items[_playlistIndex]);
      }
      return;
    }

    final rwm = _currentRwm;
    final currentSurah = state.surahNumber;
    if (rwm == null || currentSurah == null || currentSurah >= 114) return;

    final nextSurah = currentSurah + 1;
    if (rwm.moshaf.hasSurah(nextSurah)) {
      await play(rwm, nextSurah);
    }
  }

  /// Manually skip to the next surah. Uses the active playlist when in
  /// playlist mode, otherwise falls back to the current moshaf's next surah.
  Future<void> nextSurah() async {
    if (_playlist != null) {
      final items = _playlist!;
      if (_playlistIndex + 1 < items.length) {
        _playlistIndex += 1;
        await _playPlaylistItem(items[_playlistIndex]);
      }
      return;
    }
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

  /// Manually skip to the previous surah (playlist-aware).
  Future<void> previousSurah() async {
    if (_playlist != null) {
      if (_playlistIndex > 0) {
        _playlistIndex -= 1;
        await _playPlaylistItem(_playlist![_playlistIndex]);
      }
      return;
    }
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

  /// Start playing an offline playlist (ordered by surah number).
  /// When [startIndex] is given, begins at that slot; otherwise at 0.
  Future<void> playPlaylist(
    List<PlaylistItem> items, {
    int startIndex = 0,
  }) async {
    if (items.isEmpty) return;
    _stopOtherPlayers();
    _currentRwm = null;
    _playlist = List.unmodifiable(items);
    _playlistIndex = startIndex.clamp(0, items.length - 1);
    await _playPlaylistItem(_playlist![_playlistIndex]);
  }

  Future<void> _playPlaylistItem(PlaylistItem it) async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        reciterName: it.reciterName,
        moshafName: it.moshafName,
        surahNumber: it.surahNumber,
        position: Duration.zero,
        duration: Duration.zero,
      );
      await _player.setFilePath(it.filePath);

      String surahName = 'سورة ${it.surahNumber}';
      try {
        final names = await _ref.read(surahNamesProvider.future);
        if (names.containsKey(it.surahNumber)) {
          surahName = 'سورة ${names[it.surahNumber]}';
        }
      } catch (_) {}

      _attachToHandler(title: surahName, subtitle: it.reciterName);
      await _player.play();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: 'فشل تشغيل السورة المحمّلة',
      );
    }
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async => _player.play();

  Future<void> stop() async {
    await _player.stop();
    _detachFromHandler();
    _currentRwm = null;
    _playlist = null;
    _playlistIndex = 0;
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
