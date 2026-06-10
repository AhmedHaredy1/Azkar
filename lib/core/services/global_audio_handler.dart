import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Identifies which audio source is currently active.
enum ActiveAudioSource { none, quranAyah, quranListen, liveRadio }

/// Lightweight info about what's currently playing, used by the global mini player.
class GlobalAudioInfo {
  final ActiveAudioSource source;
  final String title;
  final String? subtitle;
  final bool isPlaying;
  final bool isLoading;

  const GlobalAudioInfo({
    this.source = ActiveAudioSource.none,
    this.title = '',
    this.subtitle,
    this.isPlaying = false,
    this.isLoading = false,
  });

  bool get isActive => source != ActiveAudioSource.none;
}

/// Manages the Android/iOS media notification and tracks which player is active.
class GlobalAudioHandler extends BaseAudioHandler with SeekHandler {
  AudioPlayer? _activePlayer;
  ActiveAudioSource _activeSource = ActiveAudioSource.none;
  StreamSubscription<PlayerState>? _playerStateSub;
  Uri? _cachedArtUri;
  Future<Uri?>? _artUriFuture;

  ActiveAudioSource get activeSource => _activeSource;

  /// Copies the bundled app icon to a cache file so Android media session
  /// can load it via file://. `asset:///` URIs aren't resolvable by the
  /// system notification's image loader.
  Future<Uri?> _resolveArtUri() async {
    if (_cachedArtUri != null) return _cachedArtUri;
    _artUriFuture ??= () async {
      try {
        final dir = await getApplicationSupportDirectory();
        final file = File('${dir.path}/media_art.png');
        if (!await file.exists()) {
          final bytes = await rootBundle
              .load('assets/images/app_icon.png');
          await file.writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
            flush: true,
          );
        }
        _cachedArtUri = Uri.file(file.path);
        return _cachedArtUri;
      } catch (_) {
        return null;
      }
    }();
    return _artUriFuture;
  }

  /// Called when any of our players starts playing.
  void attachPlayer(AudioPlayer player, ActiveAudioSource source,
      {required String title, String? subtitle}) {
    // If switching source, detach previous
    if (_activeSource != source || _activePlayer != player) {
      _playerStateSub?.cancel();
    }

    _activePlayer = player;
    _activeSource = source;

    // Publish metadata immediately, then update artUri once the
    // cache file is ready (first time only).
    void publish(Uri? artUri) {
      mediaItem.add(MediaItem(
        id: source.name,
        title: title,
        artist: subtitle ?? 'رفيق المسلم',
        album: _albumForSource(source),
        artUri: artUri,
      ));
    }

    publish(_cachedArtUri);
    if (_cachedArtUri == null) {
      _resolveArtUri().then((uri) {
        if (uri != null && _activeSource == source) publish(uri);
      });
    }

    // Sync player state → notification playback state
    _playerStateSub = player.playerStateStream.listen((ps) {
      playbackState.add(PlaybackState(
        controls: [
          if (ps.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1],
        processingState: _mapProcessingState(ps.processingState),
        playing: ps.playing,
      ));
    });
  }

  /// Called when audio stops completely.
  void detachPlayer() {
    _playerStateSub?.cancel();
    _activePlayer = null;
    _activeSource = ActiveAudioSource.none;

    playbackState.add(PlaybackState(
      controls: [],
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    mediaItem.add(null);
  }

  String _albumForSource(ActiveAudioSource source) {
    switch (source) {
      case ActiveAudioSource.quranAyah:
        return 'القرآن الكريم';
      case ActiveAudioSource.quranListen:
        return 'استماع القرآن';
      case ActiveAudioSource.liveRadio:
        return 'البث المباشر';
      case ActiveAudioSource.none:
        return 'رفيق المسلم';
    }
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // ── MediaSession callbacks (lock screen / notification buttons) ──

  @override
  Future<void> play() async {
    await _activePlayer?.play();
  }

  @override
  Future<void> pause() async {
    await _activePlayer?.pause();
  }

  @override
  Future<void> stop() async {
    await _activePlayer?.stop();
    detachPlayer();
  }

  @override
  Future<void> seek(Duration position) async {
    await _activePlayer?.seek(position);
  }
}

/// Singleton provider for the global audio handler.
/// Initialized in main.dart via AudioService.init().
final globalAudioHandlerProvider = Provider<GlobalAudioHandler>((ref) {
  throw UnimplementedError(
      'globalAudioHandlerProvider must be overridden at app startup');
});
