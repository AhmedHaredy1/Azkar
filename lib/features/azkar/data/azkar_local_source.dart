import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../domain/models/azkar_category.dart';

class AzkarLocalSource {
  List<AzkarCategory>? _cachedCategories;

  Future<List<AzkarCategory>> loadCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;

    final jsonString = await rootBundle.loadString(AppAssets.azkarData);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    _cachedCategories = jsonList
        .map((e) => AzkarCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cachedCategories!;
  }

  Future<AzkarCategory?> getCategoryById(String id) async {
    final categories = await loadCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
