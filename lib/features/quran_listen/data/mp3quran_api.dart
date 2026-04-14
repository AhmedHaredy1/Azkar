import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/storage_service.dart';
import '../domain/models/mp3quran_reciter.dart';

class Mp3QuranApi {
  static const _apiUrl = 'https://mp3quran.net/api/v3/reciters?language=ar';
  static const _cacheKey = 'mp3quran_reciters_cache';
  static const _cacheTimeKey = 'mp3quran_reciters_cache_time';
  static const _cacheDuration = Duration(hours: 24);

  final StorageService _storage;

  Mp3QuranApi(this._storage);

  Future<List<Mp3QuranReciter>> getReciters() async {
    // Try cache first
    final cached = _loadFromCache();
    if (cached != null) return cached;

    // Fetch from API
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final recitersJson = data['reciters'] as List<dynamic>? ?? [];
        final reciters = recitersJson
            .map((r) => Mp3QuranReciter.fromJson(r as Map<String, dynamic>))
            .toList();

        // Cache the response
        await _saveToCache(response.body);
        return reciters;
      }
    } catch (_) {
      // If network fails, try returning stale cache
      final stale = _loadFromCache(ignoreExpiry: true);
      if (stale != null) return stale;
    }

    return [];
  }

  List<Mp3QuranReciter>? _loadFromCache({bool ignoreExpiry = false}) {
    final cacheTimeMs = _storage.getSetting<int>(_cacheTimeKey);
    if (cacheTimeMs == null) return null;

    if (!ignoreExpiry) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimeMs);
      if (DateTime.now().difference(cacheTime) > _cacheDuration) return null;
    }

    final cached = _storage.getSetting<String>(_cacheKey);
    if (cached == null) return null;

    try {
      final data = json.decode(cached) as Map<String, dynamic>;
      final recitersJson = data['reciters'] as List<dynamic>? ?? [];
      return recitersJson
          .map((r) => Mp3QuranReciter.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(String responseBody) async {
    await _storage.putSetting(_cacheKey, responseBody);
    await _storage.putSetting(
        _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }
}
