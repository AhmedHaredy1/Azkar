/// The kinds of pilgrimage (نُسُك) supported by the interactive ritual
/// tracker. Pure Dart — no Flutter dependency so it can be reused freely
/// across the data and presentation layers.
enum NusukType { umrah, tamattu, qiran, ifrad }

extension NusukTypeX on NusukType {
  /// Stable string id persisted in Hive (active session + history records).
  /// NEVER change these values without a storage migration.
  String get id {
    switch (this) {
      case NusukType.umrah:
        return 'umrah';
      case NusukType.tamattu:
        return 'tamattu';
      case NusukType.qiran:
        return 'qiran';
      case NusukType.ifrad:
        return 'ifrad';
    }
  }

  /// Resolve a persisted id back to its enum value, or null if unknown.
  static NusukType? fromId(String? id) {
    for (final t in NusukType.values) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Display name (Arabic).
  String get arabicName {
    switch (this) {
      case NusukType.umrah:
        return 'العمرة';
      case NusukType.tamattu:
        return 'حج التمتّع';
      case NusukType.qiran:
        return 'حج القِران';
      case NusukType.ifrad:
        return 'حج الإفراد';
    }
  }

  /// Short one-line description shown under the name on selection cards.
  String get subtitle {
    switch (this) {
      case NusukType.umrah:
        return 'إحرام، طواف، سعي، ثم حلق أو تقصير';
      case NusukType.tamattu:
        return 'عمرة ثم حج بإحرامين — وعلى المتمتّع هَدْي';
      case NusukType.qiran:
        return 'الجمع بين الحج والعمرة بإحرام واحد مع هَدْي';
      case NusukType.ifrad:
        return 'الإفراد بالحج وحده بلا عمرة ولا هَدْي واجب';
    }
  }

  /// Umrah is the only non-Hajj nusuk. Hajj rites are limited to one record
  /// per Hijri year; Umrah is unlimited (see [NusukRepository.hasHajjInHijriYear]).
  bool get isHajj => this != NusukType.umrah;

  /// Small badge label distinguishing Hajj from Umrah on cards/history.
  String get badge => isHajj ? 'حج' : 'عمرة';
}
