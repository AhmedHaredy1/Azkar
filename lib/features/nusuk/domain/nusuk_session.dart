import 'nusuk_type.dart';

/// Runtime state of an in-progress ritual. Immutable — mutations go through
/// [copyWith] so the StateNotifier emits a fresh instance each time.
///
/// Persisted to the Hive settings box as JSON (see [NusukRepository]); every
/// nested value is a Hive-safe primitive / List / Map. [DateTime] is stored as
/// an ISO-8601 string and [Set]s as lists. Resumable across app restarts and
/// across the multi-day span of a Hajj.
class NusukSession {
  final String sessionId;
  final NusukType type;
  final DateTime startedAt;

  /// Index of the currently-active step. Steps after it stay locked.
  final int currentStepIndex;

  /// Ids of steps the user has tapped «ابدأ الخطوة» on (info steps).
  final Set<String> startedStepIds;

  /// Ids of steps fully completed.
  final Set<String> completedStepIds;

  /// stepId → current count, for counter steps (Tawaf/Sa'i/Jamarat).
  final Map<String, int> counters;

  /// stepId → chosen option id, for choice steps (e.g. 'halq'/'taqsir').
  final Map<String, String> choices;

  /// Hijri year at the moment the session was created — used to enforce the
  /// one-Hajj-per-Hijri-year rule even while the rite is still in progress.
  final int hijriYear;

  const NusukSession({
    required this.sessionId,
    required this.type,
    required this.startedAt,
    required this.hijriYear,
    this.currentStepIndex = 0,
    this.startedStepIds = const {},
    this.completedStepIds = const {},
    this.counters = const {},
    this.choices = const {},
  });

  bool isStepStarted(String id) => startedStepIds.contains(id);
  bool isStepCompleted(String id) => completedStepIds.contains(id);
  int counterOf(String id) => counters[id] ?? 0;
  String? choiceOf(String id) => choices[id];

  /// Completion ratio in `[0,1]`, given the total number of steps in the flow.
  double progressFraction(int totalSteps) =>
      totalSteps == 0 ? 0 : completedStepIds.length / totalSteps;

  /// Whether every step in a flow of [totalSteps] steps is done.
  bool isFinished(int totalSteps) =>
      totalSteps > 0 && completedStepIds.length >= totalSteps;

  NusukSession copyWith({
    int? currentStepIndex,
    Set<String>? startedStepIds,
    Set<String>? completedStepIds,
    Map<String, int>? counters,
    Map<String, String>? choices,
  }) {
    return NusukSession(
      sessionId: sessionId,
      type: type,
      startedAt: startedAt,
      hijriYear: hijriYear,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      startedStepIds: startedStepIds ?? this.startedStepIds,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      counters: counters ?? this.counters,
      choices: choices ?? this.choices,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'type': type.id,
        'startedAt': startedAt.toIso8601String(),
        'currentStepIndex': currentStepIndex,
        'startedStepIds': startedStepIds.toList(),
        'completedStepIds': completedStepIds.toList(),
        'counters': counters,
        'choices': choices,
        'hijriYear': hijriYear,
      };

  factory NusukSession.fromJson(Map<dynamic, dynamic> json) {
    return NusukSession(
      sessionId: json['sessionId']?.toString() ?? '',
      type: NusukTypeX.fromId(json['type']?.toString()) ?? NusukType.umrah,
      startedAt:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ?? DateTime.now(),
      hijriYear: _toInt(json['hijriYear']),
      currentStepIndex: _toInt(json['currentStepIndex']),
      startedStepIds: _toStringSet(json['startedStepIds']),
      completedStepIds: _toStringSet(json['completedStepIds']),
      counters: _toIntMap(json['counters']),
      choices: _toStringMap(json['choices']),
    );
  }

  // Hive round-trips loosely-typed collections (Map<dynamic,dynamic>,
  // List<dynamic>); these helpers normalize them back to strong types.
  static int _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  static Set<String> _toStringSet(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toSet() : <String>{};

  static Map<String, int> _toIntMap(dynamic v) {
    final out = <String, int>{};
    if (v is Map) {
      v.forEach((k, val) => out[k.toString()] = _toInt(val));
    }
    return out;
  }

  static Map<String, String> _toStringMap(dynamic v) {
    final out = <String, String>{};
    if (v is Map) {
      v.forEach((k, val) => out[k.toString()] = val.toString());
    }
    return out;
  }
}
