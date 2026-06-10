import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../domain/models/azkar_category.dart';

class AzkarLocalSource {
  List<AzkarCategory>? _cachedCategories;
  Map<String, AzkarCategory>? _categoryById;

  Future<List<AzkarCategory>> loadCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;

    final jsonString = await rootBundle.loadString(AppAssets.azkarData);
    final decoded = json.decode(jsonString);
    final List<dynamic> jsonList =
        decoded is Map<String, dynamic> ? (decoded['categories'] as List<dynamic>? ?? []) : decoded as List<dynamic>;
    _cachedCategories = jsonList
        .map((e) => AzkarCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    // Id → category lookup built once alongside the list, so repeated
    // getCategoryById calls stay O(1) as the catalog grows.
    _categoryById = {for (final c in _cachedCategories!) c.id: c};
    return _cachedCategories!;
  }

  Future<AzkarCategory?> getCategoryById(String id) async {
    await loadCategories();
    return _categoryById?[id];
  }
}
