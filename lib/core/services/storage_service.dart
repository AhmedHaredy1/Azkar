import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_keys.dart';

/// Riverpod entry point for [StorageService]. Feature code should resolve the
/// service through this provider (overridable in tests) instead of touching
/// [StorageService.instance] directly.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Singleton wrapper around Hive for local storage operations.
/// Manages boxes for settings, bookmarks, favorites, and sebha counter.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  /// Current on-disk schema version. Bump when a key is renamed or a
  /// serialization format changes, and add a corresponding step in [migrate].
  static const int schemaVersion = 1;

  // Box names
  static const String _settingsBox = StorageKeys.settingsBox;
  static const String _bookmarksBox = StorageKeys.bookmarksBox;
  static const String _favoritesBox = StorageKeys.favoritesBox;
  static const String _sebhaBox = StorageKeys.sebhaBox;

  late Box<dynamic> _settings;
  late Box<dynamic> _bookmarks;
  late Box<dynamic> _favorites;
  late Box<dynamic> _sebha;

  /// Initialize all Hive boxes. Must be called after Hive.initFlutter().
  Future<void> init() async {
    _settings = await Hive.openBox(_settingsBox);
    _bookmarks = await Hive.openBox(_bookmarksBox);
    _favorites = await Hive.openBox(_favoritesBox);
    _sebha = await Hive.openBox(_sebhaBox);

    await _runMigrations();
  }

  Future<void> _runMigrations() async {
    // Boxes that already contain data but have no version stamp predate the
    // versioning mechanism — they are layout v1, the same as fresh installs.
    final stored =
        _settings.get(StorageKeys.schemaVersion, defaultValue: 1) as int? ?? 1;

    if (stored < schemaVersion) {
      await migrate(stored, schemaVersion);
    }
    if (stored != schemaVersion) {
      await _settings.put(StorageKeys.schemaVersion, schemaVersion);
    } else if (!_settings.containsKey(StorageKeys.schemaVersion)) {
      await _settings.put(StorageKeys.schemaVersion, schemaVersion);
    }
  }

  /// Upgrade persisted data from layout [from] to layout [to].
  ///
  /// Each future bump of [schemaVersion] must add a step here, e.g.:
  /// ```dart
  /// if (from < 2) { /* rename key, re-encode value, ... */ }
  /// ```
  /// Steps must be idempotent — a crash mid-migration reruns them on next
  /// launch because the version stamp is only written after success.
  Future<void> migrate(int from, int to) async {
    // v1 is the baseline layout — nothing to do yet.
  }

  // --- Settings ---

  Box<dynamic> get settingsBox => _settings;

  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = _settings.get(key, defaultValue: defaultValue);
    // A wrong-typed value stored under this key would otherwise throw a cast
    // error at the call site; fall back to the default instead.
    if (value is T?) return value;
    return defaultValue;
  }

  Future<void> putSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  Future<void> deleteSetting(String key) async {
    await _settings.delete(key);
  }

  // --- Bookmarks ---

  Box<dynamic> get bookmarksBox => _bookmarks;

  List<dynamic> getBookmarks() {
    return _bookmarks.values.toList();
  }

  Future<void> addBookmark(String key, dynamic value) async {
    await _bookmarks.put(key, value);
  }

  Future<void> removeBookmark(String key) async {
    await _bookmarks.delete(key);
  }

  bool isBookmarked(String key) {
    return _bookmarks.containsKey(key);
  }

  // --- Favorites ---

  Box<dynamic> get favoritesBox => _favorites;

  List<dynamic> getFavorites() {
    return _favorites.values.toList();
  }

  Future<void> addFavorite(String key, dynamic value) async {
    await _favorites.put(key, value);
  }

  Future<void> removeFavorite(String key) async {
    await _favorites.delete(key);
  }

  bool isFavorite(String key) {
    return _favorites.containsKey(key);
  }

  // --- Sebha ---

  Box<dynamic> get sebhaBox => _sebha;

  int getSebhaCount() {
    return _sebha.get(StorageKeys.sebhaCount, defaultValue: 0) as int;
  }

  Future<void> setSebhaCount(int count) async {
    await _sebha.put(StorageKeys.sebhaCount, count);
  }

  int getSebhaTotal() {
    return _sebha.get(StorageKeys.sebhaTotal, defaultValue: 0) as int;
  }

  Future<void> setSebhaTotal(int total) async {
    await _sebha.put(StorageKeys.sebhaTotal, total);
  }

  String getSebhaDhikr() {
    return _sebha.get(StorageKeys.sebhaDhikr, defaultValue: 'سبحان الله')
        as String;
  }

  Future<void> setSebhaDhikr(String dhikr) async {
    await _sebha.put(StorageKeys.sebhaDhikr, dhikr);
  }

  // --- Generic helpers ---

  Future<void> put(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  T? get<T>(String boxName, String key, {T? defaultValue}) {
    final box = Hive.box(boxName);
    final value = box.get(key, defaultValue: defaultValue);
    if (value is T?) return value;
    return defaultValue;
  }

  Future<void> delete(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }
}
