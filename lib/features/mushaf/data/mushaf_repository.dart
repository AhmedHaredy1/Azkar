import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/services/storage_service.dart';
import '../domain/models/mushaf_type.dart';

class MushafRepository {
  static MushafRepository? _instance;
  static MushafRepository get instance => _instance ??= MushafRepository._();
  MushafRepository._() : _storage = StorageService.instance;

  /// Injectable constructor for tests — production resolves the singleton
  /// through `mushafRepositoryProvider`.
  MushafRepository.withStorage(this._storage);

  final StorageService _storage;

  String? _mushafDir;
  http.Client? _activeClient;
  bool _isDownloading = false;

  Future<String> get mushafDirectory async {
    if (_mushafDir != null) return _mushafDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/mushafs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _mushafDir = dir.path;
    return _mushafDir!;
  }

  Future<String> pathForMushaf(MushafType mushaf) async {
    final dir = await mushafDirectory;
    return '$dir/${mushaf.fileName}';
  }

  Future<bool> isDownloaded(MushafType mushaf) async {
    final path = await pathForMushaf(mushaf);
    return File(path).existsSync();
  }

  Future<Map<String, bool>> getDownloadStatus() async {
    final result = <String, bool>{};
    for (final m in availableMushafs) {
      result[m.id] = await isDownloaded(m);
    }
    return result;
  }

  Future<void> download(
    MushafType mushaf, {
    void Function(double progress, int receivedMB, int totalMB)? onProgress,
  }) async {
    if (mushaf.downloadUrl.isEmpty) {
      throw Exception('رابط التحميل غير متوفر لهذا المصحف');
    }

    // _activeClient is single-slot: a second concurrent download would
    // clobber the first one's client and orphan its cancel handle.
    if (_isDownloading) {
      throw Exception('هناك تحميل آخر قيد التنفيذ — انتظر اكتماله أولاً');
    }
    _isDownloading = true;

    final destPath = await pathForMushaf(mushaf);
    final tempPath = '$destPath.tmp';

    _activeClient = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(mushaf.downloadUrl));
      final response = await _activeClient!.send(request);

      if (response.statusCode != 200) {
        throw Exception('فشل التحميل: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final tempFile = File(tempPath);
      final sink = tempFile.openWrite();
      var received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null && contentLength > 0) {
          onProgress(
            received / contentLength,
            (received / (1024 * 1024)).round(),
            (contentLength / (1024 * 1024)).round(),
          );
        }
      }

      await sink.close();
      await File(tempPath).rename(destPath);
    } catch (e) {
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      _activeClient = null;
      _isDownloading = false;
    }
  }

  void cancelDownload() {
    _activeClient?.close();
    _activeClient = null;
    _isDownloading = false;
  }

  Future<void> deleteMushaf(MushafType mushaf) async {
    final path = await pathForMushaf(mushaf);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    await _storage.deleteSetting(StorageKeys.mushafLastPage(mushaf.id));

    final defaultId = _storage.getSetting<String>(StorageKeys.defaultMushafId);
    if (defaultId == mushaf.id) {
      await _storage.deleteSetting(StorageKeys.defaultMushafId);
      final statusMap = await getDownloadStatus();
      final fallback =
          statusMap.entries.where((e) => e.value).map((e) => e.key).firstOrNull;
      if (fallback != null) {
        await _storage.putSetting(StorageKeys.defaultMushafId, fallback);
      } else {
        await _storage.putSetting(StorageKeys.quranReadingMode, 'text');
      }
    }
  }

  Future<String?> getDefaultMushafId() async {
    return _storage.getSetting<String>(StorageKeys.defaultMushafId);
  }

  Future<void> setDefaultMushaf(String mushafId) async {
    await _storage.putSetting(StorageKeys.defaultMushafId, mushafId);
  }

  String getQuranReadingMode() {
    return _storage.getSetting<String>(StorageKeys.quranReadingMode,
            defaultValue: 'text') ??
        'text';
  }

  Future<void> setQuranReadingMode(String mode) async {
    await _storage.putSetting(StorageKeys.quranReadingMode, mode);
  }

  int getLastPdfPage(String mushafId) {
    return _storage.getSetting<int>(
          StorageKeys.mushafLastPage(mushafId),
          defaultValue: 1,
        ) ??
        1;
  }

  Future<void> setLastPdfPage(String mushafId, int page) async {
    await _storage.putSetting(StorageKeys.mushafLastPage(mushafId), page);
  }

  int mapPageBetweenMushafs({
    required MushafType from,
    required MushafType to,
    required int pdfPage,
  }) {
    final fromIdx = from.index;
    final toIdx = to.index;
    if (fromIdx == null || toIdx == null) return pdfPage;
    if (fromIdx.surahToPdfPage == toIdx.surahToPdfPage) {
      return pdfPage.clamp(1, to.totalPdfPages);
    }
    final surah = fromIdx.getSurahForPage(pdfPage) ?? 1;
    final fromStart = fromIdx.getSurahStartPage(surah);
    final fromEnd = fromIdx.getSurahEndPage(surah);
    final toStart = toIdx.getSurahStartPage(surah);
    final toEnd = toIdx.getSurahEndPage(surah);
    final fromSpan = (fromEnd - fromStart).clamp(0, 9999);
    final toSpan = (toEnd - toStart).clamp(0, 9999);
    if (fromSpan == 0 || toSpan == 0) return toStart.clamp(1, to.totalPdfPages);
    final progress = (pdfPage - fromStart) / fromSpan;
    final mapped = (toStart + progress * toSpan).round();
    return mapped.clamp(1, to.totalPdfPages);
  }
}
