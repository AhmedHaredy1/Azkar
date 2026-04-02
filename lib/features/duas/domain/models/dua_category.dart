class Dua {
  final String id;
  final String categoryId;
  final String textAr;
  final String source;
  final String note;

  const Dua({
    required this.id,
    required this.categoryId,
    required this.textAr,
    this.source = '',
    this.note = '',
  });

  factory Dua.fromJson(Map<String, dynamic> json, String catId) {
    return Dua(
      id: json['id']?.toString() ?? '',
      categoryId: catId,
      textAr: json['textAr'] as String? ?? json['text'] as String? ?? '',
      source: json['source'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class DuaCategory {
  final String id;
  final String nameAr;
  final String icon;
  final int sortOrder;
  final List<Dua> duasList;

  const DuaCategory({
    required this.id,
    required this.nameAr,
    this.icon = '',
    this.sortOrder = 0,
    this.duasList = const [],
  });

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final duasJson = json['duas'] as List<dynamic>? ?? [];
    return DuaCategory(
      id: id,
      nameAr: json['nameAr'] as String? ?? json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      duasList: duasJson.map((e) => Dua.fromJson(e as Map<String, dynamic>, id)).toList(),
    );
  }
}
