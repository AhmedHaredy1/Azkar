/// Central registry of every Hive key used across the app.
///
/// All values must stay byte-identical to what shipped before this file
/// existed — they are persisted on user devices. Never edit a value here
/// without adding a migration step in `StorageService.migrate`.
class StorageKeys {
  StorageKeys._();

  // ── Box names ──
  static const String settingsBox = 'settings';
  static const String bookmarksBox = 'bookmarks';
  static const String favoritesBox = 'favorites';
  static const String sebhaBox = 'sebha';

  // ── Schema ──
  /// Version of the on-disk storage layout. Bump together with a migration
  /// step in `StorageService.migrate`.
  static const String schemaVersion = 'storageSchemaVersion';

  // ── Settings box ──
  static const String isFirstLaunch = 'isFirstLaunch';
  static const String lastReadPage = 'lastReadPage';
  static const String highlightSurah = 'highlightSurah';
  static const String highlightAyah = 'highlightAyah';
  static const String highlightPage = 'highlightPage';
  static const String reciterId = 'reciterId';
  static const String radioFavorites = 'radioFavorites';
  static const String morningAzkarHour = 'morningAzkarHour';
  static const String morningAzkarMinute = 'morningAzkarMinute';
  static const String eveningAzkarHour = 'eveningAzkarHour';
  static const String eveningAzkarMinute = 'eveningAzkarMinute';

  // Mushaf (PDF) reading
  static const String defaultMushafId = 'defaultMushafId';
  static const String quranReadingMode = 'quranReadingMode';

  /// Per-mushaf last-page key — one entry per downloaded mushaf.
  static String mushafLastPage(String mushafId) => 'mushaf_lastpage_$mushafId';

  // Nusuk (interactive Hajj/Umrah ritual tracker)
  /// The single in-progress ritual session (JSON map), or absent when none.
  static const String nusukActiveSession = 'nusukActiveSession';

  /// The «سجلّ مناسكي» completed-ritual history (JSON list of records).
  static const String nusukHistory = 'nusukHistory';

  // ── Favorites box ──
  // Each feature stores its favorites under its own namespaced list key,
  // so azkar / dua entries can never collide.
  static const String azkarFavorites = 'azkar_favorites';
  static const String duaFavorites = 'dua_favorites';

  // ── Sebha box ──
  static const String sebhaCount = 'count';
  static const String sebhaTotal = 'total';
  static const String sebhaDhikr = 'dhikr';
}
