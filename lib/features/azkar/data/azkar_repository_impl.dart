import '../domain/models/azkar_category.dart';
import '../domain/repositories/azkar_repository.dart';
import 'azkar_local_source.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  final AzkarLocalSource _localSource;

  AzkarRepositoryImpl(this._localSource);

  @override
  Future<List<AzkarCategory>> getCategories() {
    return _localSource.loadCategories();
  }

  @override
  Future<AzkarCategory?> getCategoryById(String id) {
    return _localSource.getCategoryById(id);
  }
}
