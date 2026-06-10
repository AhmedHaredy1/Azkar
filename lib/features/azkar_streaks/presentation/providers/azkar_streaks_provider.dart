import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';

/// Kinds of azkar whose completion streak we track.
enum AzkarKind { morning, evening }

class AzkarCompletionDay {
  final DateTime date; // normalized to YYYY-MM-DD at 00:00 local
  final bool morning;
  final bool evening;
  const AzkarCompletionDay({
    required this.date,
    required this.morning,
    required this.evening,
  });
  bool get bothDone => morning && evening;
  bool get anyDone => morning || evening;
}

/// Stored in Hive `settings` box under key `azkarCompletionMap` as a
/// `Map<String, String>` — key `YYYY-MM-DD`, value one of `m`/`e`/`me`.
class AzkarStreaksState {
  final Map<String, String> raw;
  const AzkarStreaksState(this.raw);

  bool didMorning(DateTime d) => (raw[_k(d)] ?? '').contains('m');
  bool didEvening(DateTime d) => (raw[_k(d)] ?? '').contains('e');

  int get currentStreak => _computeStreak(DateTime.now());
  int get longestStreak {
    if (raw.isEmpty) return 0;
    int best = 0;
    for (final key in raw.keys) {
      final d = DateTime.tryParse(key);
      if (d == null) continue;
      final s = _computeStreak(d);
      if (s > best) best = s;
    }
    return best;
  }

  int get morningCount =>
      raw.values.where((v) => v.contains('m')).length;
  int get eveningCount =>
      raw.values.where((v) => v.contains('e')).length;

  /// Walk backwards from the given day; a day counts if either morning or
  /// evening was completed. Streak ends on the first missed day.
  int _computeStreak(DateTime from) {
    int streak = 0;
    DateTime cursor = DateTime(from.year, from.month, from.day);
    while (true) {
      final v = raw[_k(cursor)] ?? '';
      if (v.isEmpty) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _k(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class AzkarStreaksNotifier extends StateNotifier<AzkarStreaksState> {
  final StorageService _storage;
  static const _storageKey = 'azkarCompletionMap';

  AzkarStreaksNotifier(this._storage)
      : super(const AzkarStreaksState({})) {
    _load();
  }

  void _load() {
    final raw = _storage.getSetting<Map>(_storageKey);
    if (raw == null) {
      state = const AzkarStreaksState({});
      return;
    }
    final map = <String, String>{};
    raw.forEach((k, v) {
      if (k is String && v is String) map[k] = v;
    });
    state = AzkarStreaksState(map);
  }

  Future<void> markCompleted(AzkarKind kind, {DateTime? when}) async {
    final now = when ?? DateTime.now();
    final key = AzkarStreaksState._k(now);
    final existing = state.raw[key] ?? '';
    final token = kind == AzkarKind.morning ? 'm' : 'e';
    if (existing.contains(token)) return; // already recorded today
    final updated = '$existing$token';
    final newMap = Map<String, String>.from(state.raw)..[key] = updated;
    state = AzkarStreaksState(newMap);
    await _storage.putSetting(_storageKey, newMap);
  }

  Future<void> reset() async {
    state = const AzkarStreaksState({});
    await _storage.deleteSetting(_storageKey);
  }
}

final azkarStreaksProvider =
    StateNotifierProvider<AzkarStreaksNotifier, AzkarStreaksState>((ref) {
  return AzkarStreaksNotifier(ref.watch(storageServiceProvider));
});

/// Helper: match a category name string to an AzkarKind, or null if neither.
AzkarKind? azkarKindFromName(String name) {
  if (name.contains('الصباح')) return AzkarKind.morning;
  if (name.contains('المساء')) return AzkarKind.evening;
  return null;
}
