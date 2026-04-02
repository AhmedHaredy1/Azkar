class Dhikr {
  final String id;
  final String categoryId;
  final String textAr;
  final int repetitions;
  final String source;
  final String note;

  const Dhikr({
    required this.id,
    required this.categoryId,
    required this.textAr,
    required this.repetitions,
    this.source = '',
    this.note = '',
  });

  factory Dhikr.fromJson(Map<String, dynamic> json, String catId) {
    return Dhikr(
      id: json['id']?.toString() ?? '',
      categoryId: catId,
      textAr: json['textAr'] as String? ?? json['text'] as String? ?? '',
      repetitions: json['repetitions'] as int? ?? json['count'] as int? ?? 1,
      source: json['source'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class AzkarCategory {
  final String id;
  final String nameAr;
  final String icon;
  final int sortOrder;
  final List<Dhikr> azkarList;

  const AzkarCategory({
    required this.id,
    required this.nameAr,
    this.icon = '',
    this.sortOrder = 0,
    this.azkarList = const [],
  });

  factory AzkarCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final azkarJson = json['azkar'] as List<dynamic>? ?? [];
    return AzkarCategory(
      id: id,
      nameAr: json['nameAr'] as String? ?? json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      azkarList: azkarJson.map((e) => Dhikr.fromJson(e as Map<String, dynamic>, id)).toList(),
    );
  }
}
