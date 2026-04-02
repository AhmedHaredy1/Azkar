import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../domain/models/dua_category.dart';

class DuasLocalSource {
  List<DuaCategory>? _cachedCategories;

  Future<List<DuaCategory>> loadCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;

    final jsonString = await rootBundle.loadString(AppAssets.duasData);
    final decoded = json.decode(jsonString);
    final List<dynamic> jsonList =
        decoded is Map<String, dynamic> ? (decoded['categories'] as List<dynamic>? ?? []) : decoded as List<dynamic>;
    _cachedCategories = jsonList
        .map((e) => DuaCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cachedCategories!;
  }

  Future<DuaCategory?> getCategoryById(String id) async {
    final categories = await loadCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
