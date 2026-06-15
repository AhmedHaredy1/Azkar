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

// ─────────────────────────── Date enforcement ───────────────────────────

/// The date-availability verdict for a step. In [NusukMode.practice] (and for
/// steps with no [NusukStep.hajjDay]) it is always [NusukStepGate.unlocked].
/// In [NusukMode.live] a dated step is locked until its Dhul-Ḥijjah day.
class NusukStepGate {
  /// True when the step's valid Dhul-Ḥijjah day has not arrived yet.
  final bool dateLocked;

  /// Target date label «٩ ذو الحجة ١٤٤٨هـ» (only when [dateLocked]).
  final String? validDateLabel;

  /// Whole days remaining until the valid day (null when unknown).
  final int? remainingDays;

  const NusukStepGate.unlocked()
      : dateLocked = false,
        validDateLabel = null,
        remainingDays = null;

  const NusukStepGate.locked({this.validDateLabel, this.remainingDays})
      : dateLocked = true;
}

/// Compute whether [step] may be performed today given the session's [mode]
/// and reference Hijri year. Used by both the UI (to show a lock callout) and
/// the engine (to refuse mutations) so they can never disagree.
NusukStepGate nusukDateGate(NusukSession session, NusukStep step) {
  final day = step.hajjDay;
  if (session.mode == NusukMode.practice || day == null) {
    return const NusukStepGate.unlocked();
  }
  final today = HijriCalendar.now();
  if (_hijriReached(today, session.hijriYear, day)) {
    return const NusukStepGate.unlocked();
  }
  final label = '${ArabicNumberUtils.toEasternArabic(day)} '
      '${_hijriMonths[12]} '
      '${ArabicNumberUtils.toEasternArabic(session.hijriYear)}هـ';
  int? remaining;
  try {
    final target = HijriCalendar().hijriToGregorian(session.hijriYear, 12, day);
    final now = DateTime.now();
    final diff = DateTime(target.year, target.month, target.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff > 0) remaining = diff;
  } catch (_) {
    // Conversion unavailable — leave the countdown out, keep the lock.
  }
  return NusukStepGate.locked(validDateLabel: label, remainingDays: remaining);
}

/// Whether "today" (Hijri) has reached (year, Dhul-Ḥijjah=12, [day]) or later.
/// Dhul-Ḥijjah is the 12th and last month, so any earlier month in the same
/// year is "before"; a later Hijri year is "after" (the date already passed).
bool _hijriReached(HijriCalendar today, int year, int day) {
  if (today.hYear != year) return today.hYear > year;
  if (today.hMonth != 12) return false;
  return today.hDay >= day;
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
  ///
  /// [mode] applies to Hajj only: [NusukMode.live] enforces the Hijri calendar,
  /// [NusukMode.practice] lifts the date locks for learning/preview. Umrah has
  /// no dated steps, so it is always stored as [NusukMode.live].
  StartResult startSession(NusukType type, {NusukMode mode = NusukMode.live}) {
    final year = currentHijriYear();
    if (type.isHajj && _repo.hasHajjInHijriYear(year)) {
      return StartResult.blockedHajj;
    }
    final session = NusukSession(
      sessionId: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      startedAt: DateTime.now(),
      hijriYear: year,
      mode: type.isHajj ? mode : NusukMode.live,
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
    if (_dateBlocked(s)) return;
    state = s.copyWith(startedStepIds: {...s.startedStepIds, stepId});
    _persist();
  }

  /// Complete the active step. Returns the finalized [NusukRecord] when this
  /// was the last step (so the UI can show the completion screen), else null.
  NusukRecord? completeStep(String stepId) {
    final s = state;
    if (s == null || !_isActiveStep(s, stepId)) return null;
    if (_dateBlocked(s)) return null;
    return _markCompleteAndAdvance(s, stepId);
  }

  /// Tally one repetition on a counter step. Returns the finalized record when
  /// this tap completed the final step (the closing Tawaf is a counter), else null.
  NusukRecord? incrementCounter(String stepId) {
    final s = state;
    if (s == null || !_isActiveStep(s, stepId)) return null;
    if (_dateBlocked(s)) return null;
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

  /// Record the user's pick on a choice step (e.g. halq/taqsir, التعجّل/التأخّر).
  void selectChoice(String stepId, String choiceId) {
    final s = state;
    if (s == null || !_isActiveStep(s, stepId)) return;
    if (_dateBlocked(s)) return;
    state = s.copyWith(choices: {...s.choices, stepId: choiceId});
    _persist();
  }

  /// Abandon the in-progress rite without recording it.
  void cancelSession() {
    state = null;
    _repo.clearActiveSession();
  }

  /// Restart the current rite from the first step (same type + mode, fresh
  /// progress).
  void restart() {
    final s = state;
    if (s == null) return;
    state = NusukSession(
      sessionId: DateTime.now().microsecondsSinceEpoch.toString(),
      type: s.type,
      startedAt: DateTime.now(),
      hijriYear: currentHijriYear(),
      mode: s.mode,
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

  /// Whether the current active step is locked by the Hijri calendar (live mode
  /// only). Defends the engine even if the UI lets a tap through.
  bool _dateBlocked(NusukSession s) {
    final steps = stepsForType(s.type);
    if (s.currentStepIndex < 0 || s.currentStepIndex >= steps.length) {
      return false;
    }
    return nusukDateGate(s, steps[s.currentStepIndex]).dateLocked;
  }

  NusukRecord? _markCompleteAndAdvance(NusukSession s, String stepId) {
    final steps = stepsForType(s.type);
    final step = steps[s.currentStepIndex];
    // Choice steps require a selection first.
    if (step.kind == NusukStepKind.choice && s.choiceOf(stepId) == null) {
      return null;
    }
    final completed = {...s.completedStepIds, stepId};
    var skipped = s.skippedStepIds;

    // التعجّل (early departure): drop every 13 Dhul-Ḥijjah step.
    if (stepId == kNafrahStepId && s.choiceOf(stepId) == kTaajjulChoiceId) {
      skipped = {
        ...skipped,
        for (final e in steps)
          if (e.hajjDay == 13) e.id,
      };
    }

    // Advance to the next step that is neither completed nor skipped.
    var next = s.currentStepIndex + 1;
    while (next < steps.length &&
        (completed.contains(steps[next].id) ||
            skipped.contains(steps[next].id))) {
      next++;
    }
    final finished = next >= steps.length;
    final updated = s.copyWith(
      completedStepIds: completed,
      skippedStepIds: skipped,
      currentStepIndex: finished ? s.currentStepIndex : next,
    );
    if (finished) {
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
      stepsCompleted: s.completedStepIds.length,
    );
    // Practice/training runs are NOT recorded in «سجلّ مناسكي» — they still show
    // the celebration, but leave no permanent record and don't consume the
    // year's single real Hajj.
    if (s.mode == NusukMode.live) {
      _ref.read(nusukHistoryProvider.notifier).add(record);
    }
    _repo.clearActiveSession();
    state = null;
    return record;
  }

  void _persist() {
    final s = state;
    if (s != null) _repo.saveActiveSession(s);
  }
}
