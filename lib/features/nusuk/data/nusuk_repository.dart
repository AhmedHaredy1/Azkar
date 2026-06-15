import '../../../core/constants/storage_keys.dart';
import '../../../core/services/storage_service.dart';
import '../domain/nusuk_record.dart';
import '../domain/nusuk_session.dart';
import '../domain/nusuk_type.dart';

/// Persistence for the Nusuk tracker. Stores everything as JSON-safe
/// maps/lists in the Hive **settings** box via [StorageService] — the same
/// approach the rest of the app uses (no Hive TypeAdapters).
///
/// Layout:
///  - [StorageKeys.nusukActiveSession] → one session map (the in-progress rite).
///  - [StorageKeys.nusukHistory]       → list of completed-record maps.
class NusukRepository {
  final StorageService _storage;

  NusukRepository(this._storage);

  // ─────────────────────────── Active session ───────────────────────────

  /// The current in-progress session, or null if none. Returns null (rather
  /// than throwing) on any malformed/legacy payload so the UI can recover.
  NusukSession? loadActiveSession() {
    final raw = _storage.getSetting<Map>(StorageKeys.nusukActiveSession);
    if (raw == null) return null;
    try {
      return NusukSession.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveSession(NusukSession session) {
    return _storage.putSetting(
        StorageKeys.nusukActiveSession, session.toJson());
  }

  Future<void> clearActiveSession() {
    return _storage.deleteSetting(StorageKeys.nusukActiveSession);
  }

  // ────────────────────────────── History ──────────────────────────────

  /// All completed rituals, newest first. Malformed entries are skipped.
  List<NusukRecord> loadHistory() {
    final raw = _storage.getSetting<List>(StorageKeys.nusukHistory);
    if (raw == null) return [];
    final out = <NusukRecord>[];
    for (final item in raw) {
      if (item is Map) {
        try {
          out.add(NusukRecord.fromJson(item));
        } catch (_) {
          // skip a corrupt record rather than failing the whole list
        }
      }
    }
    out.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return out;
  }

  Future<void> addRecord(NusukRecord record) {
    final all = loadHistory()..add(record);
    return _saveHistory(all);
  }

  Future<void> deleteRecord(String recordId) {
    final all = loadHistory()..removeWhere((r) => r.recordId == recordId);
    return _saveHistory(all);
  }

  Future<void> _saveHistory(List<NusukRecord> records) {
    return _storage.putSetting(
      StorageKeys.nusukHistory,
      records.map((r) => r.toJson()).toList(),
    );
  }

  // ───────────────────── Hajj one-per-Hijri-year rule ─────────────────────

  /// True when a Hajj (any of Tamattuʿ/Qirān/Ifrād) is already recorded — or
  /// currently in progress — for [hijriYear]. Umrah is never restricted.
  bool hasHajjInHijriYear(int hijriYear) {
    final inHistory = loadHistory()
        .any((r) => r.type.isHajj && r.hijriYear == hijriYear);
    if (inHistory) return true;

    final active = loadActiveSession();
    return active != null &&
        active.type.isHajj &&
        active.hijriYear == hijriYear;
  }
}
