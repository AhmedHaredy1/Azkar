import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/azkar_local_source.dart';
import '../../data/azkar_repository_impl.dart';
import '../../domain/models/azkar_category.dart';
import '../../domain/repositories/azkar_repository.dart';

// Data source & repository providers
final azkarLocalSourceProvider = Provider<AzkarLocalSource>((ref) {
  return AzkarLocalSource();
});

final azkarRepositoryProvider = Provider<AzkarRepository>((ref) {
  return AzkarRepositoryImpl(ref.read(azkarLocalSourceProvider));
});

// Categories list
final azkarCategoriesProvider = FutureProvider<List<AzkarCategory>>((ref) {
  return ref.read(azkarRepositoryProvider).getCategories();
});

// Single category by ID
final azkarCategoryProvider =
    FutureProvider.family<AzkarCategory?, String>((ref, id) {
  return ref.read(azkarRepositoryProvider).getCategoryById(id);
});

// ──────────────────────────────────────────────
// Azkar Progress State
// ──────────────────────────────────────────────

class AzkarProgressState {
  final int currentIndex;
  final int remainingCount;
  final int completedCount;
  final bool isCompleted;
  // Key identifying the currently loaded azkar category — used to decide
  // whether to preserve progress when re-entering the same category.
  final String categoryKey;
  // Per-dhikr remaining-count snapshot, keyed by index in the azkarList.
  // Kept in memory only (no persistence) so that switching between dhikrs
  // within the same session remembers partial progress.
  final Map<int, int> perItemRemaining;

  const AzkarProgressState({
    this.currentIndex = 0,
    this.remainingCount = 0,
    this.completedCount = 0,
    this.isCompleted = false,
    this.categoryKey = '',
    this.perItemRemaining = const {},
  });

  AzkarProgressState copyWith({
    int? currentIndex,
    int? remainingCount,
    int? completedCount,
    bool? isCompleted,
    String? categoryKey,
    Map<int, int>? perItemRemaining,
  }) {
    return AzkarProgressState(
      currentIndex: currentIndex ?? this.currentIndex,
      remainingCount: remainingCount ?? this.remainingCount,
      completedCount: completedCount ?? this.completedCount,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryKey: categoryKey ?? this.categoryKey,
      perItemRemaining: perItemRemaining ?? this.perItemRemaining,
    );
  }
}

class AzkarProgressNotifier extends StateNotifier<AzkarProgressState> {
  AzkarProgressNotifier() : super(const AzkarProgressState());

  int _remainingFor(int index, List<Dhikr> azkarList) {
    return state.perItemRemaining[index] ?? azkarList[index].repetitions;
  }

  /// Initialize for a category. If [categoryKey] matches the one already in
  /// state, per-item progress is preserved. Otherwise state is fully reset.
  void initialize(List<Dhikr> azkarList, {String categoryKey = ''}) {
    if (azkarList.isEmpty) {
      state = const AzkarProgressState(isCompleted: true);
      return;
    }

    // Same category as before → keep accumulated progress.
    if (categoryKey.isNotEmpty && categoryKey == state.categoryKey) {
      // Clamp current index in case the list size changed.
      final idx = state.currentIndex.clamp(0, azkarList.length - 1);
      state = state.copyWith(
        currentIndex: idx,
        remainingCount: _remainingFor(idx, azkarList),
        isCompleted: false,
      );
      return;
    }

    state = AzkarProgressState(
      currentIndex: 0,
      remainingCount: azkarList.first.repetitions,
      completedCount: 0,
      categoryKey: categoryKey,
      perItemRemaining: const {},
    );
  }

  /// Decrements the counter. Returns true if advanced to next dhikr.
  bool decrementAndAdvance(List<Dhikr> azkarList) {
    if (state.isCompleted) return false;

    final currentIdx = state.currentIndex;
    final newRemaining = state.remainingCount - 1;
    final nextMap = Map<int, int>.from(state.perItemRemaining);

    if (newRemaining > 0) {
      nextMap[currentIdx] = newRemaining;
      state = state.copyWith(
        remainingCount: newRemaining,
        perItemRemaining: nextMap,
      );
      return false;
    }

    // This dhikr is done — mark it as 0 and increment completed count.
    nextMap[currentIdx] = 0;
    final newCompleted = state.completedCount + 1;

    // Move to next dhikr.
    final nextIndex = currentIdx + 1;
    if (nextIndex >= azkarList.length) {
      state = state.copyWith(
        isCompleted: true,
        remainingCount: 0,
        completedCount: newCompleted,
        perItemRemaining: nextMap,
      );
      return false;
    }

    state = state.copyWith(
      currentIndex: nextIndex,
      remainingCount: _remainingFor(nextIndex, azkarList),
      completedCount: newCompleted,
      perItemRemaining: nextMap,
    );
    return true;
  }

  /// Full reset — clears per-item progress for the current category.
  void reset(List<Dhikr> azkarList) {
    if (azkarList.isEmpty) {
      state = const AzkarProgressState(isCompleted: true);
      return;
    }
    state = AzkarProgressState(
      currentIndex: 0,
      remainingCount: azkarList.first.repetitions,
      completedCount: 0,
      categoryKey: state.categoryKey,
      perItemRemaining: const {},
    );
  }

  /// Jump to next dhikr without completing the current one. Preserves any
  /// previously partial progress for the destination dhikr.
  bool goToNext(List<Dhikr> azkarList) {
    if (azkarList.isEmpty) return false;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= azkarList.length) return false;
    state = state.copyWith(
      currentIndex: nextIndex,
      remainingCount: _remainingFor(nextIndex, azkarList),
    );
    return true;
  }

  /// Jump to previous dhikr. Preserves any previously partial progress.
  bool goToPrevious(List<Dhikr> azkarList) {
    if (azkarList.isEmpty) return false;
    final prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) return false;
    state = state.copyWith(
      currentIndex: prevIndex,
      remainingCount: _remainingFor(prevIndex, azkarList),
      isCompleted: false,
    );
    return true;
  }
}

final azkarProgressProvider =
    StateNotifierProvider<AzkarProgressNotifier, AzkarProgressState>((ref) {
  return AzkarProgressNotifier();
});

// ──────────────────────────────────────────────
// Favorites State
// ──────────────────────────────────────────────

class AzkarFavoritesNotifier extends StateNotifier<Set<String>> {
  final StorageService _storage;

  AzkarFavoritesNotifier(this._storage) : super({}) {
    _loadFavorites();
  }

  static const String _hiveKey = StorageKeys.azkarFavorites;

  void _loadFavorites() {
    final saved = _storage.favoritesBox.get(_hiveKey);
    if (saved != null && saved is List) {
      state = saved.cast<String>().toSet();
    }
  }

  Future<void> _saveFavorites() async {
    await _storage.favoritesBox.put(_hiveKey, state.toList());
  }

  /// Toggle favorite status for a dhikr. Key = "categoryId:dhikrId"
  Future<void> toggleFavorite(String dhikrKey) async {
    final newSet = Set<String>.from(state);
    if (newSet.contains(dhikrKey)) {
      newSet.remove(dhikrKey);
    } else {
      newSet.add(dhikrKey);
    }
    state = newSet;
    await _saveFavorites();
  }

  bool isFavorite(String dhikrKey) {
    return state.contains(dhikrKey);
  }
}

final azkarFavoritesProvider =
    StateNotifierProvider<AzkarFavoritesNotifier, Set<String>>((ref) {
  return AzkarFavoritesNotifier(ref.watch(storageServiceProvider));
});

/// Provides all favorited Dhikr items across all categories
final favoritedAzkarListProvider =
    FutureProvider<List<(AzkarCategory, Dhikr)>>((ref) async {
  final favorites = ref.watch(azkarFavoritesProvider);
  final categories =
      await ref.read(azkarRepositoryProvider).getCategories();

  final List<(AzkarCategory, Dhikr)> result = [];
  for (final cat in categories) {
    for (final dhikr in cat.azkarList) {
      final key = '${cat.id}:${dhikr.id}';
      if (favorites.contains(key)) {
        result.add((cat, dhikr));
      }
    }
  }
  return result;
});
