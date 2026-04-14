class Mp3QuranMoshaf {
  final int id;
  final String name;
  final int moshafType;
  final String server;
  final int surahTotal;
  final List<int> surahList;

  const Mp3QuranMoshaf({
    required this.id,
    required this.name,
    required this.moshafType,
    required this.server,
    required this.surahTotal,
    required this.surahList,
  });

  factory Mp3QuranMoshaf.fromJson(Map<String, dynamic> json) {
    final surahListStr = json['surah_list'] as String? ?? '';
    final surahs = surahListStr
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((n) => n > 0)
        .toList();

    return Mp3QuranMoshaf(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      moshafType: json['moshaf_type'] as int? ?? 0,
      server: json['server'] as String? ?? '',
      surahTotal: json['surah_total'] as int? ?? 0,
      surahList: surahs,
    );
  }

  bool hasSurah(int surahNumber) => surahList.contains(surahNumber);

  String getAudioUrl(int surahNumber) {
    return '$server${surahNumber.toString().padLeft(3, '0')}.mp3';
  }
}

class Mp3QuranReciter {
  final int id;
  final String name;
  final String letter;
  final List<Mp3QuranMoshaf> moshaf;

  const Mp3QuranReciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.moshaf,
  });

  factory Mp3QuranReciter.fromJson(Map<String, dynamic> json) {
    final moshafList = (json['moshaf'] as List<dynamic>?)
            ?.map((m) => Mp3QuranMoshaf.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return Mp3QuranReciter(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      letter: json['letter'] as String? ?? '',
      moshaf: moshafList,
    );
  }
}

/// Known moshaf type names for display
const moshafTypeNames = <int, String>{
  11: 'مرتل',
  14: 'مرتل (خاص)',
  21: 'ورش عن نافع',
  31: 'خلف عن حمزة',
  41: 'البزي عن ابن كثير',
  51: 'قالون عن نافع',
  61: 'قنبل عن ابن كثير',
  71: 'السوسي عن أبي عمرو',
  81: 'قالون (أبي نشيط)',
  91: 'يعقوب الحضرمي',
  101: 'ورش (الأصبهاني)',
  111: 'البزي وقنبل',
  121: 'الدوري عن الكسائي',
  131: 'الدوري عن أبي عمرو',
  151: 'شعبة عن عاصم',
  161: 'ابن ذكوان عن ابن عامر',
  181: 'ورش (الأزرق)',
  191: 'هشام عن ابي عامر',
  201: 'ابن جماز عن أبي جعفر',
  213: 'المصحف المعلم',
  222: 'المصحف المجود',
};
