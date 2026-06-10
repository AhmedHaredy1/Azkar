import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_providers.dart';
import '../../../../core/services/surah_download_service.dart';

class ActiveDownload {
  final int reciterId;
  final int moshafId;
  final int surah;
  final double progress; // 0..1, -1 for unknown
  final String? error;
  const ActiveDownload({
    required this.reciterId,
    required this.moshafId,
    required this.surah,
    required this.progress,
    this.error,
  });
  String get key => '${reciterId}_${moshafId}_$surah';
  ActiveDownload copyWith({double? progress, String? error}) => ActiveDownload(
        reciterId: reciterId,
        moshafId: moshafId,
        surah: surah,
        progress: progress ?? this.progress,
        error: error ?? this.error,
      );
}

class DownloadsState {
  final Set<String> downloadedKeys;
  final Map<String, ActiveDownload> active;
  const DownloadsState({
    this.downloadedKeys = const {},
    this.active = const {},
  });
  DownloadsState copyWith({
    Set<String>? downloadedKeys,
    Map<String, ActiveDownload>? active,
  }) =>
      DownloadsState(
        downloadedKeys: downloadedKeys ?? this.downloadedKeys,
        active: active ?? this.active,
      );
}

class DownloadsNotifier extends StateNotifier<DownloadsState> {
  final SurahDownloadService _downloads;

  DownloadsNotifier(this._downloads) : super(const DownloadsState()) {
    refresh();
  }

  final Map<String, bool> _cancelFlags = {};

  Future<void> refresh() async {
    final keys = await _downloads.downloadedKeys();
    state = state.copyWith(downloadedKeys: keys.toSet());
  }

  Future<void> download(
    int reciterId,
    int moshafId,
    int surah,
    String url,
  ) async {
    final key = _downloads.trackKey(reciterId, moshafId, surah);
    if (state.active.containsKey(key) || state.downloadedKeys.contains(key)) {
      return;
    }
    _cancelFlags[key] = false;
    final entry = ActiveDownload(
      reciterId: reciterId,
      moshafId: moshafId,
      surah: surah,
      progress: 0,
    );
    state = state.copyWith(
      active: {...state.active, key: entry},
    );

    try {
      await _downloads.download(
        reciterId,
        moshafId,
        surah,
        url,
        cancelled: () => _cancelFlags[key] == true,
        onProgress: (p) {
          final current = state.active[key];
          if (current == null) return;
          state = state.copyWith(
            active: {
              ...state.active,
              key: current.copyWith(progress: p),
            },
          );
        },
      );
      final newActive = Map<String, ActiveDownload>.from(state.active)
        ..remove(key);
      state = state.copyWith(
        downloadedKeys: {...state.downloadedKeys, key},
        active: newActive,
      );
    } catch (e) {
      final newActive = Map<String, ActiveDownload>.from(state.active)
        ..remove(key);
      state = state.copyWith(active: newActive);
    } finally {
      _cancelFlags.remove(key);
    }
  }

  void cancel(String key) {
    _cancelFlags[key] = true;
  }

  Future<void> delete(int reciterId, int moshafId, int surah) async {
    await _downloads.delete(reciterId, moshafId, surah);
    await refresh();
  }

  Future<void> clearAll() async {
    await _downloads.clearAll();
    await refresh();
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadsNotifier, DownloadsState>((ref) {
  return DownloadsNotifier(ref.watch(surahDownloadServiceProvider));
});
