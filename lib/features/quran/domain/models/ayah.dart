class Ayah {
  final int number;
  final String textAr;
  final int juz;
  final int page;

  const Ayah({
    required this.number,
    required this.textAr,
    this.juz = 1,
    this.page = 1,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] as int? ?? json['numberInSurah'] as int? ?? 0,
      textAr: json['text'] as String? ?? '',
      juz: json['juz'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
    );
  }
}
