import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final azkarCategoryProvider = FutureProvider.family<AzkarCategory?, String>((ref, id) {
  return ref.read(azkarRepositoryProvider).getCategoryById(id);
});

// Azkar progress state
class AzkarProgressState {
  final int currentIndex;
  final int remainingCount;
  final bool isCompleted;

  const AzkarProgressState({
    this.currentIndex = 0,
    this.remainingCount = 0,
    this.isCompleted = false,
  });

  AzkarProgressState copyWith({
    int? currentIndex,
    int? remainingCount,
    bool? isCompleted,
  }) {
    return AzkarProgressState(
      currentIndex: currentIndex ?? this.currentIndex,
      remainingCount: remainingCount ?? this.remainingCount,
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
    );
  }

  /// Returns true if advanced to next dhikr, false if all completed
  bool decrementAndAdvance(List<Dhikr> azkarList) {
    if (state.isCompleted) return false;

    final newRemaining = state.remainingCount - 1;
    if (newRemaining > 0) {
      state = state.copyWith(remainingCount: newRemaining);
      return false;
    }

    // Move to next dhikr
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= azkarList.length) {
      state = state.copyWith(isCompleted: true, remainingCount: 0);
      return false;
    }

    state = AzkarProgressState(
      currentIndex: nextIndex,
      remainingCount: azkarList[nextIndex].repetitions,
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
