import 'package:hive_flutter/hive_flutter.dart';

/// Singleton wrapper around Hive for local storage operations.
/// Manages boxes for settings, bookmarks, favorites, and sebha counter.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  // Box names
  static const String _settingsBox = 'settings';
  static const String _bookmarksBox = 'bookmarks';
  static const String _favoritesBox = 'favorites';
  static const String _sebhaBox = 'sebha';

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
  }

  // --- Settings ---

  Box<dynamic> get settingsBox => _settings;

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue) as T?;
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
    return _sebha.get('count', defaultValue: 0) as int;
  }

  Future<void> setSebhaCount(int count) async {
    await _sebha.put('count', count);
  }

  int getSebhaTotal() {
    return _sebha.get('total', defaultValue: 0) as int;
  }

  Future<void> setSebhaTotal(int total) async {
    await _sebha.put('total', total);
  }

  String getSebhaDhikr() {
    return _sebha.get('dhikr', defaultValue: 'سبحان الله') as String;
  }

  Future<void> setSebhaDhikr(String dhikr) async {
    await _sebha.put('dhikr', dhikr);
  }

  // --- Generic helpers ---

  Future<void> put(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  T? get<T>(String boxName, String key, {T? defaultValue}) {
    final box = Hive.box(boxName);
    return box.get(key, defaultValue: defaultValue) as T?;
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
