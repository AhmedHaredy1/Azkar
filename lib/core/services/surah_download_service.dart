import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Per-surah download service for the Qur'an Listen feature. Files are
/// stored in the app's private documents dir under `quran_audio/<id>.mp3`.
/// IDs are deterministic `<reciterId>_<moshafId>_<surah>` strings so we
/// can look up the local file from any call site.
class SurahDownloadService {
  SurahDownloadService._();
  static final SurahDownloadService instance = SurahDownloadService._();

  Directory? _dir;

  Future<Directory> _audioDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory('${docs.path}/quran_audio');
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d;
    return d;
  }

  String trackKey(int reciterId, int moshafId, int surah) =>
      '${reciterId}_${moshafId}_$surah';

  Future<File> trackFile(int reciterId, int moshafId, int surah) async {
    final d = await _audioDir();
    return File('${d.path}/${trackKey(reciterId, moshafId, surah)}.mp3');
  }

  Future<bool> exists(int reciterId, int moshafId, int surah) async {
    final f = await trackFile(reciterId, moshafId, surah);
    return f.existsSync();
  }

  /// Downloads the track. [onProgress] receives a 0..1 ratio; -1 means the
  /// total is unknown (chunked). Throws on non-200 or IO failure.
  Future<void> download(
    int reciterId,
    int moshafId,
    int surah,
    String url, {
    void Function(double progress)? onProgress,
    bool Function()? cancelled,
  }) async {
    final file = await trackFile(reciterId, moshafId, surah);
    if (file.existsSync()) return;

    final tmp = File('${file.path}.part');
    if (tmp.existsSync()) await tmp.delete();

    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url));
      final resp = await client.send(req).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw HttpException('HTTP ${resp.statusCode}');
      }
      final total = resp.contentLength ?? -1;
      int received = 0;
      final sink = tmp.openWrite();
      await for (final chunk in resp.stream) {
        if (cancelled?.call() == true) {
          await sink.close();
          if (tmp.existsSync()) await tmp.delete();
          throw StateError('cancelled');
        }
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        } else if (onProgress != null) {
          onProgress(-1);
        }
      }
      await sink.close();
      await tmp.rename(file.path);
    } finally {
      client.close();
    }
  }

  Future<void> delete(int reciterId, int moshafId, int surah) async {
    final f = await trackFile(reciterId, moshafId, surah);
    if (f.existsSync()) await f.delete();
  }

  /// Returns a list of downloaded track keys (no extension) currently on disk.
  Future<List<String>> downloadedKeys() async {
    final d = await _audioDir();
    if (!await d.exists()) return const [];
    return d
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mp3'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.mp3', ''))
        .toList();
  }

  Future<int> totalBytes() async {
    final d = await _audioDir();
    if (!await d.exists()) return 0;
    int sum = 0;
    for (final f in d.listSync().whereType<File>()) {
      sum += await f.length();
    }
    return sum;
  }

  Future<void> clearAll() async {
    final d = await _audioDir();
    if (!await d.exists()) return;
    for (final entity in d.listSync()) {
      if (entity is File) await entity.delete();
    }
  }
}
