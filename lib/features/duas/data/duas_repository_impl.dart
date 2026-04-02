import '../domain/models/dua_category.dart';
import '../domain/repositories/duas_repository.dart';
import 'duas_local_source.dart';

class DuasRepositoryImpl implements DuasRepository {
  final DuasLocalSource _localSource;

  DuasRepositoryImpl(this._localSource);

  @override
  Future<List<DuaCategory>> getCategories() {
    return _localSource.loadCategories();
  }

  @override
  Future<DuaCategory?> getCategoryById(String id) {
    return _localSource.getCategoryById(id);
  }
}
