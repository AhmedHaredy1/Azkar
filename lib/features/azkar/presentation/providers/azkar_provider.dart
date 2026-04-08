import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  const AzkarProgressState({
    this.currentIndex = 0,
    this.remainingCount = 0,
    this.completedCount = 0,
    this.isCompleted = false,
  });

  AzkarProgressState copyWith({
    int? currentIndex,
    int? remainingCount,
    int? completedCount,
    bool? isCompleted,
  }) {
    return AzkarProgressState(
      currentIndex: currentIndex ?? this.currentIndex,
      remainingCount: remainingCount ?? this.remainingCount,
      completedCount: completedCount ?? this.completedCount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class AzkarProgressNotifier extends StateNotifier<AzkarProgressState> {
  AzkarProgressNotifier() : super(const AzkarProgressState());

  void initialize(List<Dhikr> azkarList) {
    if (azkarList.isEmpty) {
      state = const AzkarProgressState(isCompleted: true);
      return;
    }
    state = AzkarProgressState(
      currentIndex: 0,
      remainingCount: azkarList.first.repetitions,
      completedCount: 0,
    );
  }

  /// Decrements the counter. Returns true if advanced to next dhikr.
  bool decrementAndAdvance(List<Dhikr> azkarList) {
    if (state.isCompleted) return false;

    final newRemaining = state.remainingCount - 1;
    if (newRemaining > 0) {
      state = state.copyWith(remainingCount: newRemaining);
      return false;
    }

    // This dhikr is done — increment completed count
    final newCompleted = state.completedCount + 1;

    // Move to next dhikr
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= azkarList.length) {
      state = state.copyWith(
        isCompleted: true,
        remainingCount: 0,
        completedCount: newCompleted,
      );
      return false;
    }

    state = AzkarProgressState(
      currentIndex: nextIndex,
      remainingCount: azkarList[nextIndex].repetitions,
      completedCount: newCompleted,
    );
    return true;
  }

  void reset(List<Dhikr> azkarList) {
    initialize(azkarList);
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
  AzkarFavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  static const String _hiveKey = 'azkar_favorites';

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
  return AzkarFavoritesNotifier();
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
