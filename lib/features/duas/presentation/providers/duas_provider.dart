import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';
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

// ──────────────────────────────────────────────
// Duas Favorites State
// ──────────────────────────────────────────────

class DuaFavoritesNotifier extends StateNotifier<Set<String>> {
  DuaFavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  static const String _hiveKey = 'dua_favorites';

  void _loadFavorites() {
    final storage = StorageService.instance;
    final saved = storage.favoritesBox.get(_hiveKey);
    if (saved != null && saved is List) {
      state = saved.cast<String>().toSet();
    }
  }

  Future<void> _saveFavorites() async {
    final storage = StorageService.instance;
    await storage.favoritesBox.put(_hiveKey, state.toList());
  }

  /// Toggle favorite status for a dua. Key = "categoryId:duaId"
  Future<void> toggleFavorite(String duaKey) async {
    final newSet = Set<String>.from(state);
    if (newSet.contains(duaKey)) {
      newSet.remove(duaKey);
    } else {
      newSet.add(duaKey);
    }
    state = newSet;
    await _saveFavorites();
  }

  bool isFavorite(String duaKey) {
    return state.contains(duaKey);
  }
}

final duaFavoritesProvider =
    StateNotifierProvider<DuaFavoritesNotifier, Set<String>>((ref) {
  return DuaFavoritesNotifier();
});

/// Provides all favorited Dua items across all categories
final favoritedDuasListProvider =
    FutureProvider<List<(DuaCategory, Dua)>>((ref) async {
  final favorites = ref.watch(duaFavoritesProvider);
  final categories =
      await ref.read(duasRepositoryProvider).getCategories();

  final List<(DuaCategory, Dua)> result = [];
  for (final cat in categories) {
    for (final dua in cat.duasList) {
      final key = '${cat.id}:${dua.id}';
      if (favorites.contains(key)) {
        result.add((cat, dua));
      }
    }
  }
  return result;
});
