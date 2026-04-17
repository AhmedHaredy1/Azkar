import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';

/// Location mode: auto-detect GPS or manual city selection.
enum LocationMode { auto, manual }

class AppSettingsState {
  final double fontSize;
  final String calculationMethod;
  final ThemeMode themeMode;
  final double? latitude;
  final double? longitude;
  final String? cityName;
  final String? countryName;
  final double? utcOffsetHours; // UTC offset for the selected location
  final LocationMode locationMode;

  // Notification toggles
  final bool notifyFajr;
  final bool notifyDhuhr;
  final bool notifyAsr;
  final bool notifyMaghrib;
  final bool notifyIsha;
  final bool notifyMorningAzkar;
  final bool notifyEveningAzkar;

  // Adhan settings
  final String adhanReciterId; // which muezzin for prayer notifications
  final bool playAdhan; // whether to play adhan sound with prayer notification

  const AppSettingsState({
    this.fontSize = 22.0,
    this.calculationMethod = 'UmmAlQura',
    this.themeMode = ThemeMode.system,
    this.latitude,
    this.longitude,
    this.cityName,
    this.countryName,
    this.utcOffsetHours,
    this.locationMode = LocationMode.manual,
    this.notifyFajr = true,
    this.notifyDhuhr = true,
    this.notifyAsr = true,
    this.notifyMaghrib = true,
    this.notifyIsha = true,
    this.notifyMorningAzkar = true,
    this.notifyEveningAzkar = true,
    this.adhanReciterId = 'adhan1',
    this.playAdhan = true,
  });

  /// Get the UTC offset as Duration, or null if not set.
  Duration? get utcOffset =>
      utcOffsetHours != null ? Duration(minutes: (utcOffsetHours! * 60).round()) : null;

  AppSettingsState copyWith({
    double? fontSize,
    String? calculationMethod,
    ThemeMode? themeMode,
    double? latitude,
    double? longitude,
    String? cityName,
    String? countryName,
    double? utcOffsetHours,
    LocationMode? locationMode,
    bool? notifyFajr,
    bool? notifyDhuhr,
    bool? notifyAsr,
    bool? notifyMaghrib,
    bool? notifyIsha,
    bool? notifyMorningAzkar,
    bool? notifyEveningAzkar,
    String? adhanReciterId,
    bool? playAdhan,
  }) {
    return AppSettingsState(
      fontSize: fontSize ?? this.fontSize,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      themeMode: themeMode ?? this.themeMode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      countryName: countryName ?? this.countryName,
      utcOffsetHours: utcOffsetHours ?? this.utcOffsetHours,
      locationMode: locationMode ?? this.locationMode,
      notifyFajr: notifyFajr ?? this.notifyFajr,
      notifyDhuhr: notifyDhuhr ?? this.notifyDhuhr,
      notifyAsr: notifyAsr ?? this.notifyAsr,
      notifyMaghrib: notifyMaghrib ?? this.notifyMaghrib,
      notifyIsha: notifyIsha ?? this.notifyIsha,
      notifyMorningAzkar: notifyMorningAzkar ?? this.notifyMorningAzkar,
      notifyEveningAzkar: notifyEveningAzkar ?? this.notifyEveningAzkar,
      adhanReciterId: adhanReciterId ?? this.adhanReciterId,
      playAdhan: playAdhan ?? this.playAdhan,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(const AppSettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final fontSize = _storage.getSetting<double>('fontSize', defaultValue: 22.0) ?? 22.0;
    final method =
        _storage.getSetting<String>('calculationMethod', defaultValue: 'UmmAlQura') ??
            'UmmAlQura';
    final themeModeStr =
        _storage.getSetting<String>('themeMode', defaultValue: 'system') ?? 'system';
    final latitude = _storage.getSetting<double>('latitude');
    final longitude = _storage.getSetting<double>('longitude');
    final cityName = _storage.getSetting<String>('cityName');
    final countryName = _storage.getSetting<String>('countryName');
    final utcOffsetHours = _storage.getSetting<double>('utcOffsetHours');
    final locationModeStr =
        _storage.getSetting<String>('locationMode', defaultValue: 'manual') ?? 'manual';

    // Notification toggles
    final notifyFajr = _storage.getSetting<bool>('notifyFajr', defaultValue: true) ?? true;
    final notifyDhuhr = _storage.getSetting<bool>('notifyDhuhr', defaultValue: true) ?? true;
    final notifyAsr = _storage.getSetting<bool>('notifyAsr', defaultValue: true) ?? true;
    final notifyMaghrib =
        _storage.getSetting<bool>('notifyMaghrib', defaultValue: true) ?? true;
    final notifyIsha = _storage.getSetting<bool>('notifyIsha', defaultValue: true) ?? true;
    final notifyMorningAzkar =
        _storage.getSetting<bool>('notifyMorningAzkar', defaultValue: true) ?? true;
    final notifyEveningAzkar =
        _storage.getSetting<bool>('notifyEveningAzkar', defaultValue: true) ?? true;

    // Adhan settings
    final adhanReciterId =
        _storage.getSetting<String>('adhanReciterId', defaultValue: 'mishary') ?? 'mishary';
    final playAdhan = _storage.getSetting<bool>('playAdhan', defaultValue: true) ?? true;

    state = AppSettingsState(
      fontSize: fontSize,
      calculationMethod: method,
      themeMode: _themeModeFromString(themeModeStr),
      latitude: latitude,
      longitude: longitude,
      cityName: cityName,
      countryName: countryName,
      utcOffsetHours: utcOffsetHours,
      locationMode: locationModeStr == 'auto' ? LocationMode.auto : LocationMode.manual,
      notifyFajr: notifyFajr,
      notifyDhuhr: notifyDhuhr,
      notifyAsr: notifyAsr,
      notifyMaghrib: notifyMaghrib,
      notifyIsha: notifyIsha,
      notifyMorningAzkar: notifyMorningAzkar,
      notifyEveningAzkar: notifyEveningAzkar,
      adhanReciterId: adhanReciterId,
      playAdhan: playAdhan,
    );
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _storage.putSetting('fontSize', size);
  }

  Future<void> setCalculationMethod(String method) async {
    state = state.copyWith(calculationMethod: method);
    await _storage.putSetting('calculationMethod', method);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.putSetting('themeMode', _themeModeToString(mode));
  }

  Future<void> setLocation(double lat, double lon,
      {String? city, String? country, double? utcOffsetHours}) async {
    state = state.copyWith(latitude: lat, longitude: lon, cityName: city, countryName: country);
    await _storage.putSetting('latitude', lat);
    await _storage.putSetting('longitude', lon);
    if (city != null) {
      await _storage.putSetting('cityName', city);
    }
    if (country != null) {
      await _storage.putSetting('countryName', country);
    }
    if (utcOffsetHours != null) {
      state = state.copyWith(utcOffsetHours: utcOffsetHours);
      await _storage.putSetting('utcOffsetHours', utcOffsetHours);
    }

    // Auto-detect best calculation method
    final autoMethod = _detectCalculationMethod(lat, lon);
    if (autoMethod != null) {
      state = state.copyWith(calculationMethod: autoMethod);
      await _storage.putSetting('calculationMethod', autoMethod);
    }
  }

  Future<void> setLocationMode(LocationMode mode) async {
    state = state.copyWith(locationMode: mode);
    await _storage.putSetting(
        'locationMode', mode == LocationMode.auto ? 'auto' : 'manual');
  }

  /// Apply a GPS auto-detected location. Clears the previously selected manual
  /// city/country and its UTC offset so stale values don't leak into the UI or
  /// prayer-time calculations (device local time is used when utcOffset is null).
  Future<void> setAutoDetectedLocation(double lat, double lon,
      {String? city, String? country}) async {
    state = AppSettingsState(
      fontSize: state.fontSize,
      calculationMethod: state.calculationMethod,
      themeMode: state.themeMode,
      latitude: lat,
      longitude: lon,
      cityName: city,
      countryName: country,
      utcOffsetHours: null,
      locationMode: LocationMode.auto,
      notifyFajr: state.notifyFajr,
      notifyDhuhr: state.notifyDhuhr,
      notifyAsr: state.notifyAsr,
      notifyMaghrib: state.notifyMaghrib,
      notifyIsha: state.notifyIsha,
      notifyMorningAzkar: state.notifyMorningAzkar,
      notifyEveningAzkar: state.notifyEveningAzkar,
      adhanReciterId: state.adhanReciterId,
      playAdhan: state.playAdhan,
    );
    await _storage.putSetting('latitude', lat);
    await _storage.putSetting('longitude', lon);
    if (city != null) {
      await _storage.putSetting('cityName', city);
    } else {
      await _storage.deleteSetting('cityName');
    }
    if (country != null) {
      await _storage.putSetting('countryName', country);
    } else {
      await _storage.deleteSetting('countryName');
    }
    await _storage.deleteSetting('utcOffsetHours');
    await _storage.putSetting('locationMode', 'auto');

    final autoMethod = _detectCalculationMethod(lat, lon);
    if (autoMethod != null) {
      state = state.copyWith(calculationMethod: autoMethod);
      await _storage.putSetting('calculationMethod', autoMethod);
    }
  }

  /// Detect the best calculation method based on coordinates.
  static String? _detectCalculationMethod(double lat, double lng) {
    // Egypt region (lat ~22-32, lng ~24-37)
    if (lat >= 22 && lat <= 32 && lng >= 24 && lng <= 37) return 'Egyptian';
    // Gulf region — UAE, Qatar, Bahrain, Oman (lat ~20-27, lng ~50-60)
    if (lat >= 20 && lat <= 27 && lng >= 50 && lng <= 60) return 'Dubai';
    // Saudi Arabia (lat ~16-32, lng ~36-56)
    if (lat >= 16 && lat <= 32 && lng >= 36 && lng <= 56) return 'UmmAlQura';
    // Kuwait (lat ~28-30, lng ~46-49)
    if (lat >= 28 && lat <= 30.5 && lng >= 46 && lng <= 49) return 'Kuwait';
    // Qatar (lat ~24-27, lng ~50-52)
    if (lat >= 24 && lat <= 27 && lng >= 50 && lng <= 52) return 'Qatar';
    // Turkey, North Africa, Europe — MuslimWorldLeague
    if (lat >= 30 && lng >= -10 && lng <= 45) return 'MuslimWorldLeague';
    // Southeast Asia (Singapore, Malaysia, Indonesia)
    if (lat >= -11 && lat <= 8 && lng >= 95 && lng <= 142) return 'Singapore';
    // Pakistan, India, Bangladesh
    if (lat >= 5 && lat <= 38 && lng >= 60 && lng <= 93) return 'Karachi';
    // North America
    if (lat >= 15 && lat <= 72 && lng >= -170 && lng <= -50) return 'NorthAmerica';
    return null;
  }

  Future<void> setAdhanReciter(String reciterId) async {
    state = state.copyWith(adhanReciterId: reciterId);
    await _storage.putSetting('adhanReciterId', reciterId);
  }

  Future<void> setPlayAdhan(bool value) async {
    state = state.copyWith(playAdhan: value);
    await _storage.putSetting('playAdhan', value);
  }

  Future<void> setNotificationToggle(String key, bool value) async {
    switch (key) {
      case 'fajr':
        state = state.copyWith(notifyFajr: value);
        await _storage.putSetting('notifyFajr', value);
      case 'dhuhr':
        state = state.copyWith(notifyDhuhr: value);
        await _storage.putSetting('notifyDhuhr', value);
      case 'asr':
        state = state.copyWith(notifyAsr: value);
        await _storage.putSetting('notifyAsr', value);
      case 'maghrib':
        state = state.copyWith(notifyMaghrib: value);
        await _storage.putSetting('notifyMaghrib', value);
      case 'isha':
        state = state.copyWith(notifyIsha: value);
        await _storage.putSetting('notifyIsha', value);
      case 'morningAzkar':
        state = state.copyWith(notifyMorningAzkar: value);
        await _storage.putSetting('notifyMorningAzkar', value);
      case 'eveningAzkar':
        state = state.copyWith(notifyEveningAzkar: value);
        await _storage.putSetting('notifyEveningAzkar', value);
    }
  }

  static ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsState>((ref) {
  return SettingsNotifier(StorageService.instance);
});

/// Convenience provider for theme mode — used by app.dart
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
