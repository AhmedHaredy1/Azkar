import '../models/azkar_category.dart';

abstract class AzkarRepository {
  Future<List<AzkarCategory>> getCategories();
  Future<AzkarCategory?> getCategoryById(String id);
}
