import '../models/dua_category.dart';

abstract class DuasRepository {
  Future<List<DuaCategory>> getCategories();
  Future<DuaCategory?> getCategoryById(String id);
}
