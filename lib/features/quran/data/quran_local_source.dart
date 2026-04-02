import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../domain/models/surah.dart';

class QuranLocalSource {
  List<Surah>? _cachedSurahs;

  Future<List<Surah>> loadSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;

    final jsonString = await rootBundle.loadString(AppAssets.quranData);
    final decoded = json.decode(jsonString);

    List<dynamic> jsonList;
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      final data = decoded['data'];
      if (data is Map<String, dynamic> && data.containsKey('surahs')) {
        jsonList = data['surahs'] as List<dynamic>;
      } else if (data is List<dynamic>) {
        jsonList = data;
      } else {
        jsonList = [];
      }
    } else if (decoded is List<dynamic>) {
      jsonList = decoded;
    } else {
      jsonList = [];
    }

    _cachedSurahs = jsonList
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cachedSurahs!;
  }

  Future<Surah?> getSurahByNumber(int number) async {
    final surahs = await loadSurahs();
    try {
      return surahs.firstWhere((s) => s.number == number);
    } catch (_) {
      return null;
    }
  }
}
