import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../data/nusuk_repository.dart';
import '../../domain/nusuk_flows.dart';
import '../../domain/nusuk_record.dart';
import '../../domain/nusuk_session.dart';
import '../../domain/nusuk_step.dart';
import '../../domain/nusuk_type.dart';

/// Outcome of [NusukSessionNotifier.startSession]. [blockedHajj] means the
/// one-Hajj-per-Hijri-year rule rejected the request.
enum StartResult { started, blockedHajj }

const List<String> _hijriMonths = [
  '',
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

/// Format a Hijri date as «١٠ ذو الحجة ١٤٤٨هـ» (Eastern-Arabic digits).
String formatHijriDate(HijriCalendar h) {
  final day = ArabicNumberUtils.toEasternArabic(h.hDay);
  final month = (h.hMonth >= 1 && h.hMonth <= 12) ? _hijriMonths[h.hMonth] : '';
  final year = ArabicNumberUtils.toEasternArabic(h.hYear);
  return '$day $month $yearهـ';
}

/// Current Hijri year — used by the Hajj guard and the hub display.
int currentHijriYear() => HijriCalendar.now().hYear;

const List<String> _gregorianMonths = [
  '',
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// Format a Gregorian date as «٢٥ يونيو ٢٠٢٦» (Eastern-Arabic digits).
String formatGregorianDate(DateTime d) {
  final month = (d.month >= 1 && d.month <= 12) ? _gregorianMonths[d.month] : '';
  return '${ArabicNumberUtils.toEasternArabic(d.day)} $month '
      '${ArabicNumberUtils.toEasternArabic(d.year)}';
}

/// Format a clock time as «٣:٤٥ م» (12-hour, Arabic ص/م).
String formatClockTime(DateTime d) {
  final period = d.hour < 12 ? 'ص' : 'م';
  var hour = d.hour % 12;
  if (hour == 0) hour = 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '${ArabicNumberUtils.toEasternArabic(hour)}:'
      '${ArabicNumberUtils.toEasternArabicFromString(minute)} $period';
}

// ─────────────────────────────── Providers ───────────────────────────────

final nusukRepositoryProvider = Provider<NusukRepository>((ref) {
  return NusukRepository(ref.watch(storageServiceProvider));
});

final nusukHistoryProvider =
    StateNotifierProvider<NusukHistoryNotifier, List<NusukRecord>>((ref) {
  return NusukHistoryNotifier(ref.watch(nusukRepositoryProvider));
});

final nusukSessionProvider =
    StateNotifierProvider<NusukSessionNotifier, NusukSession?>((ref) {
  return NusukSessionNotifier(ref, ref.watch(nusukRepositoryProvider));
});

// ───────────────────────────── History notifier ─────────────────────────────

class NusukHistoryNotifier extends StateNotifier<List<NusukRecord>> {
  final NusukRepository _repo;

  NusukHistoryNotifier(this._repo) : super(const []) {
    state = _repo.loadHistory();
  }

  Future<void> add(NusukRecord record) async {
    await _repo.addRecord(record);
    state = _repo.loadHistory();
  }

  Future<void> delete(String recordId) async {
    await _repo.deleteRecord(recordId);
    state = _repo.loadHistory();
  }

  void refresh() => state = _repo.loadHistory();
}

// ──────────────────────────── Session engine ────────────────────────────

/// The interactive-ritual engine. Holds the single active [NusukSession] (or
/// null) and enforces the rules:
///  - steps cannot be skipped (only the step at [NusukSession.currentStepIndex]
///    accepts input),
///  - counter steps auto-complete at their target,
///  - choice steps require a selection before completing,
///  - finishing the last step writes a [NusukRecord] to history and clears the
///    active session.
///
/// Every mutation is persisted immediately, so a rite resumes after an app
/// restart and across the multi-day span of a Hajj.
class NusukSessionNotifier extends StateNotifier<NusukSession?> {
  final Ref _ref;
  final NusukRepository _repo;

  NusukSessionNotifier(this._ref, this._repo) : super(null) {
    state = _repo.loadActiveSession();
  }

  /// Begin a new rite. Replaces any existing session (the UI confirms first).
  /// Returns [StartResult.blockedHajj] when a Hajj already exists this Hijri year.
  StartResult startSession(NusukType type) {
    final year = currentHijriYear();
    if (type.isHajj && _repo.hasHajjInHijriYear(year)) {
      return StartResult.blockedHajj;
    }
    final session = NusukSession(
      sessionId: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      startedAt: DateTime.now(),
      hijriYear: year,
    );
    state = session;
    _persist();
    return StartResult.started;
  }

  /// Mark an info step's «ابدأ الخطوة» as pressed (cosmetic gating so «أكملت
  /// الخطوة» appears after the user has begun).
  void startStep(String stepId) {
    final s = state;
    if (s == null || !_isActiveStep(s, stepId)) return;
    state = s.copyWith(startedStepIds: {...s.startedStepIds, stepId});
    _persist();
  }

  /// Complete the active step. Returns the finalized [NusukRecord] when this
  /// was the last step (so the UI can show the completion screen), else null.
  NusukRecord? completeStep(String stepId) {
    final s = state;
    if (s == null || !_isActiveStep(s, stepId)) return null;
    return _markCompleteAndAdvance(s, stepId);
  }

  /// Tally one repetition on a counter step. Returns the finalized record when
  /// this tap completed the final step (the closing Tawaf is a counter), else null.
  NusukRecord? incrementCounter(String stepId) {
    final s = state;
    if (s == null || !_isActiveStep(s, stepId)) return null;
    final step = stepsForType(s.type)[s.currentStepIndex];
    if (step.kind != NusukStepKind.counter) return null;
    final target = step.counterTarget ?? 0;
    final current = s.counterOf(stepId);
    if (current >= target) return null;

    final next = current + 1;
    final withCounter = s.copyWith(counters: {...s.counters, stepId: next});
    if (next >= target) {
      return _markCompleteAndAdvance(withCounter, stepId);
    }
    state = withCounter;
    _persist();
    return null;
  }

  /// Record the user's pick on a choice step (e.g. halq/taqsir).
  void selectChoice(String stepId, String choiceId) {
    final s = state;
    if (s == null || !_isActiveStep(s, stepId)) return;
    state = s.copyWith(choices: {...s.choices, stepId: choiceId});
    _persist();
  }

  /// Abandon the in-progress rite without recording it.
  void cancelSession() {
    state = null;
    _repo.clearActiveSession();
  }

  /// Restart the current rite from the first step (same type, fresh progress).
  void restart() {
    final s = state;
    if (s == null) return;
    state = NusukSession(
      sessionId: DateTime.now().microsecondsSinceEpoch.toString(),
      type: s.type,
      startedAt: DateTime.now(),
      hijriYear: currentHijriYear(),
    );
    _persist();
  }

  // ── internals ──

  bool _isActiveStep(NusukSession s, String stepId) {
    final steps = stepsForType(s.type);
    if (s.currentStepIndex < 0 || s.currentStepIndex >= steps.length) {
      return false;
    }
    return steps[s.currentStepIndex].id == stepId &&
        !s.completedStepIds.contains(stepId);
  }

  NusukRecord? _markCompleteAndAdvance(NusukSession s, String stepId) {
    final steps = stepsForType(s.type);
    final step = steps[s.currentStepIndex];
    // Choice steps require a selection first.
    if (step.kind == NusukStepKind.choice && s.choiceOf(stepId) == null) {
      return null;
    }
    final completed = {...s.completedStepIds, stepId};
    final isLast = s.currentStepIndex >= steps.length - 1;
    final updated = s.copyWith(
      completedStepIds: completed,
      currentStepIndex: isLast ? s.currentStepIndex : s.currentStepIndex + 1,
    );
    if (completed.length >= steps.length) {
      return _finalize(updated);
    }
    state = updated;
    _persist();
    return null;
  }

  NusukRecord _finalize(NusukSession s) {
    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);
    final record = NusukRecord(
      recordId: s.sessionId,
      type: s.type,
      completedAt: now,
      hijriDateStr: formatHijriDate(hijri),
      hijriYear: hijri.hYear,
      startedAt: s.startedAt,
    );
    _ref.read(nusukHistoryProvider.notifier).add(record);
    _repo.clearActiveSession();
    state = null;
    return record;
  }

  void _persist() {
    final s = state;
    if (s != null) _repo.saveActiveSession(s);
  }
}
