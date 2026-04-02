import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/duas_local_source.dart';
import '../../data/duas_repository_impl.dart';
import '../../domain/models/dua_category.dart';
import '../../domain/repositories/duas_repository.dart';

final duasLocalSourceProvider = Provider<DuasLocalSource>((ref) {
  return DuasLocalSource();
});

final duasRepositoryProvider = Provider<DuasRepository>((ref) {
  return DuasRepositoryImpl(ref.read(duasLocalSourceProvider));
});

final duasCategoriesProvider = FutureProvider<List<DuaCategory>>((ref) {
  return ref.read(duasRepositoryProvider).getCategories();
});

final duaCategoryProvider = FutureProvider.family<DuaCategory?, String>((ref, id) {
  return ref.read(duasRepositoryProvider).getCategoryById(id);
});
