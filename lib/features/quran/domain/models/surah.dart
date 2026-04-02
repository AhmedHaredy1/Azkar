import 'ayah.dart';

class Surah {
  final int number;
  final String nameAr;
  final String nameEn;
  final int ayahCount;
  final String revelationType;
  final List<Ayah> ayahs;

  const Surah({
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.ayahCount,
    required this.revelationType,
    this.ayahs = const [],
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    final ayahsJson = json['ayahs'] as List<dynamic>? ?? [];
    return Surah(
      number: json['number'] as int? ?? 0,
      nameAr: json['name'] as String? ?? json['nameAr'] as String? ?? '',
      nameEn: json['englishName'] as String? ?? json['nameEn'] as String? ?? '',
      ayahCount: json['numberOfAyahs'] as int? ?? json['ayahCount'] as int? ?? ayahsJson.length,
      revelationType: json['revelationType'] as String? ?? '',
      ayahs: ayahsJson.map((e) => Ayah.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
