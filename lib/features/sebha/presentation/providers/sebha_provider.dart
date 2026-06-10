import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';
import '../../domain/models/sebha_state.dart';

class SebhaNotifier extends StateNotifier<SebhaState> {
  final StorageService _storage;

  SebhaNotifier(this._storage)
      : super(SebhaState(
          totalCount: _storage.getSebhaTotal(),
          selectedDhikr: _storage.getSebhaDhikr(),
        ));

  void increment() {
    final newCurrent = state.currentCount + 1;
    final newTotal = state.totalCount + 1;
    state = state.copyWith(
      currentCount: newCurrent,
      totalCount: newTotal,
    );
    _storage.setSebhaTotal(newTotal);
  }

  void resetCurrent() {
    state = state.copyWith(currentCount: 0);
  }

  void resetAll() {
    state = state.copyWith(currentCount: 0, totalCount: 0);
    _storage.setSebhaTotal(0);
  }

  void setTarget(int target) {
    state = state.copyWith(targetCount: target);
  }

  void selectDhikr(String dhikr) {
    state = state.copyWith(selectedDhikr: dhikr, currentCount: 0);
    _storage.setSebhaDhikr(dhikr);
  }
}

final sebhaProvider = StateNotifierProvider<SebhaNotifier, SebhaState>((ref) {
  return SebhaNotifier(ref.watch(storageServiceProvider));
});
