import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mushaf_repository.dart';
import '../../domain/models/mushaf_type.dart';

final mushafRepositoryProvider = Provider<MushafRepository>((ref) {
  return MushafRepository.instance;
});

final mushafDownloadStatusProvider =
    FutureProvider<Map<String, bool>>((ref) async {
  return ref.read(mushafRepositoryProvider).getDownloadStatus();
});

final defaultMushafIdProvider = FutureProvider<String?>((ref) async {
  return ref.read(mushafRepositoryProvider).getDefaultMushafId();
});

final quranReadingModeProvider = StateProvider<String>((ref) {
  return ref.read(mushafRepositoryProvider).getQuranReadingMode();
});

final lastPdfPageProvider = StateProvider.family<int, String>((ref, mushafId) {
  return ref.read(mushafRepositoryProvider).getLastPdfPage(mushafId);
});

/// The mushaf the PDF reader will actually open: the user's default if it is
/// downloaded, otherwise the first downloaded one, or null when none exist.
final activeMushafProvider = FutureProvider<MushafType?>((ref) async {
  final statusMap = await ref.watch(mushafDownloadStatusProvider.future);
  final defaultId = await ref.watch(defaultMushafIdProvider.future);

  String? targetId;
  if (defaultId != null && (statusMap[defaultId] ?? false)) {
    targetId = defaultId;
  } else {
    targetId =
        statusMap.entries.where((e) => e.value).map((e) => e.key).firstOrNull;
  }
  return targetId == null ? null : getMushafById(targetId);
});

enum MushafActionStatus { idle, downloading, deleting, error }

class MushafActionState {
  final MushafActionStatus status;
  final String? mushafId;
  final double progress;
  final int receivedMB;
  final int totalMB;
  final String? errorMessage;

  const MushafActionState({
    this.status = MushafActionStatus.idle,
    this.mushafId,
    this.progress = 0.0,
    this.receivedMB = 0,
    this.totalMB = 0,
    this.errorMessage,
  });

  MushafActionState copyWith({
    MushafActionStatus? status,
    String? mushafId,
    double? progress,
    int? receivedMB,
    int? totalMB,
    String? errorMessage,
  }) {
    return MushafActionState(
      status: status ?? this.status,
      mushafId: mushafId ?? this.mushafId,
      progress: progress ?? this.progress,
      receivedMB: receivedMB ?? this.receivedMB,
      totalMB: totalMB ?? this.totalMB,
      errorMessage: errorMessage,
    );
  }
}

class MushafActionNotifier extends StateNotifier<MushafActionState> {
  final MushafRepository _repo;
  final Ref _ref;

  MushafActionNotifier(this._repo, this._ref)
      : super(const MushafActionState());

  Future<void> downloadMushaf(MushafType mushaf) async {
    state = MushafActionState(
      status: MushafActionStatus.downloading,
      mushafId: mushaf.id,
    );
    try {
      await _repo.download(
        mushaf,
        onProgress: (progress, receivedMB, totalMB) {
          if (!mounted) return;
          state = state.copyWith(
            progress: progress,
            receivedMB: receivedMB,
            totalMB: totalMB,
          );
        },
      );
      _ref.invalidate(mushafDownloadStatusProvider);
      state = const MushafActionState();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('ClientException') || msg.contains('Connection closed')) {
        state = const MushafActionState();
      } else {
        state = MushafActionState(
          status: MushafActionStatus.error,
          mushafId: mushaf.id,
          errorMessage: msg,
        );
      }
    }
  }

  void cancelDownload() {
    _repo.cancelDownload();
    state = const MushafActionState();
  }

  Future<void> deleteMushaf(MushafType mushaf) async {
    state = MushafActionState(
      status: MushafActionStatus.deleting,
      mushafId: mushaf.id,
    );
    try {
      await _repo.deleteMushaf(mushaf);
      _ref.invalidate(mushafDownloadStatusProvider);
      _ref.invalidate(defaultMushafIdProvider);
      final mode = _repo.getQuranReadingMode();
      _ref.read(quranReadingModeProvider.notifier).state = mode;
      state = const MushafActionState();
    } catch (e) {
      state = MushafActionState(
        status: MushafActionStatus.error,
        mushafId: mushaf.id,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setDefault(String mushafId) async {
    await _repo.setDefaultMushaf(mushafId);
    _ref.invalidate(defaultMushafIdProvider);
  }

  Future<void> setReadingMode(String mode) async {
    await _repo.setQuranReadingMode(mode);
    _ref.read(quranReadingModeProvider.notifier).state = mode;
  }
}

final mushafActionProvider =
    StateNotifierProvider<MushafActionNotifier, MushafActionState>((ref) {
  return MushafActionNotifier(ref.read(mushafRepositoryProvider), ref);
});

final mushafFilePathProvider =
    FutureProvider.family<String?, String>((ref, mushafId) async {
  final mushaf = getMushafById(mushafId);
  if (mushaf == null) return null;
  final repo = ref.read(mushafRepositoryProvider);
  final downloaded = await repo.isDownloaded(mushaf);
  if (!downloaded) return null;
  return repo.pathForMushaf(mushaf);
});
