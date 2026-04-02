class Bookmark {
  final int surahNumber;
  final int ayahNumber;
  final DateTime createdAt;

  const Bookmark({
    required this.surahNumber,
    required this.ayahNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      surahNumber: json['surahNumber'] as int? ?? 0,
      ayahNumber: json['ayahNumber'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get key => '${surahNumber}_$ayahNumber';
}
