import 'nusuk_type.dart';

/// A completed ritual stored permanently in the «سجلّ مناسكي» history.
/// Immutable, JSON-serializable (Hive settings box). Both Gregorian
/// ([completedAt]) and Hijri ([hijriDateStr], [hijriYear]) are captured at the
/// moment of completion so the log reads correctly regardless of when it's
/// viewed.
class NusukRecord {
  final String recordId;
  final NusukType type;
  final DateTime completedAt;

  /// Pre-formatted Hijri date, e.g. «١٠ ذو الحجة ١٤٤٨هـ».
  final String hijriDateStr;

  /// Hijri year of completion — drives the one-Hajj-per-year rule.
  final int hijriYear;

  /// Status of the record. Currently always 'completed'; reserved for future
  /// states without a storage migration.
  final String status;

  final DateTime? startedAt;

  /// Number of steps actually completed in this rite (excludes any dropped by
  /// التعجّل). Null on older records — callers fall back to the flow length.
  final int? stepsCompleted;

  const NusukRecord({
    required this.recordId,
    required this.type,
    required this.completedAt,
    required this.hijriDateStr,
    required this.hijriYear,
    this.status = 'completed',
    this.startedAt,
    this.stepsCompleted,
  });

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'type': type.id,
        'completedAt': completedAt.toIso8601String(),
        'hijriDateStr': hijriDateStr,
        'hijriYear': hijriYear,
        'status': status,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (stepsCompleted != null) 'stepsCompleted': stepsCompleted,
      };

  factory NusukRecord.fromJson(Map<dynamic, dynamic> json) {
    final startedRaw = json['startedAt']?.toString();
    final stepsRaw = json['stepsCompleted'];
    return NusukRecord(
      recordId: json['recordId']?.toString() ?? '',
      type: NusukTypeX.fromId(json['type']?.toString()) ?? NusukType.umrah,
      completedAt:
          DateTime.tryParse(json['completedAt']?.toString() ?? '') ??
              DateTime.now(),
      hijriDateStr: json['hijriDateStr']?.toString() ?? '',
      hijriYear: json['hijriYear'] is num
          ? (json['hijriYear'] as num).toInt()
          : int.tryParse(json['hijriYear']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'completed',
      startedAt:
          startedRaw == null ? null : DateTime.tryParse(startedRaw),
      stepsCompleted: stepsRaw is num
          ? stepsRaw.toInt()
          : int.tryParse(stepsRaw?.toString() ?? ''),
    );
  }
}
