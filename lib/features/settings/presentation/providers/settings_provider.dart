import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';

class AppSettingsState {
  final double fontSize;
  final String calculationMethod;
  final ThemeMode themeMode;
  final double? latitude;
  final double? longitude;
  final String? cityName;

  // Notification toggles (UI-only for now — scheduling comes later)
  final bool notifyFajr;
  final bool notifyDhuhr;
  final bool notifyAsr;
  final bool notifyMaghrib;
  final bool notifyIsha;
  final bool notifyMorningAzkar;
  final bool notifyEveningAzkar;

  const AppSettingsState({
    this.fontSize = 22.0,
    this.calculationMethod = 'UmmAlQura',
    this.themeMode = ThemeMode.system,
    this.latitude,
    this.longitude,
    this.cityName,
    this.notifyFajr = true,
    this.notifyDhuhr = true,
    this.notifyAsr = true,
    this.notifyMaghrib = true,
    this.notifyIsha = true,
    this.notifyMorningAzkar = true,
    this.notifyEveningAzkar = true,
  });

  AppSettingsState copyWith({
    double? fontSize,
    String? calculationMethod,
    ThemeMode? themeMode,
    double? latitude,
    double? longitude,
    String? cityName,
    bool? notifyFajr,
    bool? notifyDhuhr,
    bool? notifyAsr,
    bool? notifyMaghrib,
    bool? notifyIsha,
    bool? notifyMorningAzkar,
    bool? notifyEveningAzkar,
  }) {
    return AppSettingsState(
      fontSize: fontSize ?? this.fontSize,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      themeMode: themeMode ?? this.themeMode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      notifyFajr: notifyFajr ?? this.notifyFajr,
      notifyDhuhr: notifyDhuhr ?? this.notifyDhuhr,
      notifyAsr: notifyAsr ?? this.notifyAsr,
      notifyMaghrib: notifyMaghrib ?? this.notifyMaghrib,
      notifyIsha: notifyIsha ?? this.notifyIsha,
      notifyMorningAzkar: notifyMorningAzkar ?? this.notifyMorningAzkar,
      notifyEveningAzkar: notifyEveningAzkar ?? this.notifyEveningAzkar,
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

    state = AppSettingsState(
      fontSize: fontSize,
      calculationMethod: method,
      themeMode: _themeModeFromString(themeModeStr),
      latitude: latitude,
      longitude: longitude,
      cityName: cityName,
      notifyFajr: notifyFajr,
      notifyDhuhr: notifyDhuhr,
      notifyAsr: notifyAsr,
      notifyMaghrib: notifyMaghrib,
      notifyIsha: notifyIsha,
      notifyMorningAzkar: notifyMorningAzkar,
      notifyEveningAzkar: notifyEveningAzkar,
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

  Future<void> setLocation(double lat, double lon, {String? city}) async {
    state = state.copyWith(latitude: lat, longitude: lon, cityName: city);
    await _storage.putSetting('latitude', lat);
    await _storage.putSetting('longitude', lon);
    if (city != null) {
      await _storage.putSetting('cityName', city);
    }
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
