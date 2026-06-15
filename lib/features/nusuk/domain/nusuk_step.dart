/// A single ritual step within a Nusuk flow. These are *static definitions*
/// (the script of the rite) — runtime progress lives in [NusukSession], keyed
/// by [NusukStep.id]. Pure Dart, no Flutter dependency.
///
/// Three kinds drive the session UI:
///  - [NusukStepKind.info]    → read description / talbiyah / duas, then mark done.
///  - [NusukStepKind.counter] → tally [counterTarget] repetitions (Tawaf/Sa'i
///                              circuits, Jamarat pebbles); auto-completes at target.
///  - [NusukStepKind.choice]  → pick one of [choices] (e.g. Halq vs Taqsir), then done.
enum NusukStepKind { info, counter, choice }

/// One selectable option for a [NusukStepKind.choice] step.
class NusukChoice {
  /// Stable id persisted in the session (e.g. 'halq', 'taqsir').
  final String id;
  final String label;
  final String? note;

  const NusukChoice({required this.id, required this.label, this.note});
}

class NusukStep {
  /// Stable id, unique within a single flow. Used as the key for runtime
  /// progress in [NusukSession]; do not reuse across positions in a flow.
  final String id;
  final String title;
  final NusukStepKind kind;

  /// Long guidance body (supports `\n` line breaks like the existing guide).
  final String description;

  /// Optional ma'thur duas for this stage (rendered in Amiri).
  final List<String> duas;

  /// Talbiyah text surfaced prominently on ihram/intention steps.
  final String? talbiyah;

  /// Short practical tip shown in a highlighted callout.
  final String? guidance;

  /// Day/time context for multi-day Hajj steps, e.g. «يوم التروية — ٨ ذو الحجة».
  final String? dayLabel;

  /// The Dhul-Ḥijjah day (8…13) on which this step first becomes valid, used
  /// for Hijri-date enforcement in [NusukMode.live]. `null` = not date-gated
  /// (available whenever the sequence reaches it — e.g. ihram, Tawaf, Saʿy).
  /// The month is always Dhul-Ḥijjah (12) for Hajj-season rites, so only the
  /// day is stored. Steps tagged with day 13 are the ones dropped on التعجّل.
  final int? hajjDay;

  /// Number of repetitions for a [NusukStepKind.counter] step (e.g. 7).
  final int? counterTarget;

  /// Singular unit label for the counter (e.g. «شوط», «جمرة»).
  final String counterUnit;

  /// Options for a [NusukStepKind.choice] step.
  final List<NusukChoice> choices;

  const NusukStep({
    required this.id,
    required this.title,
    this.kind = NusukStepKind.info,
    this.description = '',
    this.duas = const [],
    this.talbiyah,
    this.guidance,
    this.dayLabel,
    this.hajjDay,
    this.counterTarget,
    this.counterUnit = 'شوط',
    this.choices = const [],
  });
}
