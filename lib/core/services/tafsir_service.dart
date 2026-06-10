import 'dart:convert';

import 'package:http/http.dart' as http;

/// Tafsir IDs recognized by the public Quran.com v4 API.
/// 16 = Al-Muyassar (Arabic), 169 = As-Sa'di (Arabic).
class TafsirService {
  TafsirService._();
  static final TafsirService instance = TafsirService._();

  static const int muyassarId = 16;

  final Map<String, String> _cache = {};

  Future<String> byAyah({
    required int surah,
    required int ayah,
    int tafsirId = muyassarId,
  }) async {
    final key = '$tafsirId:$surah:$ayah';
    final cached = _cache[key];
    if (cached != null) return cached;

    final uri = Uri.parse(
      'https://api.quran.com/api/v4/tafsirs/$tafsirId/by_ayah/$surah:$ayah',
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    // API returns `{ tafsir: { text: "<html>..." } }` or
    // `{ tafsirs: [{ text: "..." }] }` depending on version.
    String? text;
    if (data['tafsir'] is Map) {
      text = (data['tafsir'] as Map)['text'] as String?;
    } else if (data['tafsirs'] is List && (data['tafsirs'] as List).isNotEmpty) {
      final first = (data['tafsirs'] as List).first as Map;
      text = first['text'] as String?;
    }
    if (text == null || text.isEmpty) {
      throw Exception('لا يوجد تفسير متاح');
    }
    // Strip simple HTML tags — the API often embeds <p>, <i>, <sup>.
    final stripped = text.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    _cache[key] = stripped;
    return stripped;
  }
}
