import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_providers.dart';
import '../../../../core/services/adhan_audio_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/theme_palette.dart';

/// Location mode: auto-detect GPS or manual city selection.
enum LocationMode { auto, manual }

class AppSettingsState {
  final double fontSize;
  final String calculationMethod;
  final ThemeMode themeMode;
  final String themeColorId;
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

  // Pre-prayer reminder timing (in minutes; 0 = disabled)
  // When [useGlobalReminder] is true, every prayer uses [reminderMinutesGlobal].
  // When false, each prayer uses its own per-prayer value.
  final bool useGlobalReminder;
  final int reminderMinutesGlobal;
  final int reminderMinutesFajr;
  final int reminderMinutesDhuhr;
  final int reminderMinutesAsr;
  final int reminderMinutesMaghrib;
  final int reminderMinutesIsha;

  // Post-prayer dhikr reminder
  final bool notifyPostPrayerDhikr; // schedule a reminder N min after adhan
  final int postPrayerDhikrDelayMinutes; // 0 disables (default 5)

  const AppSettingsState({
    this.fontSize = 22.0,
    this.calculationMethod = 'UmmAlQura',
    this.themeMode = ThemeMode.light,
    this.themeColorId = 'green',
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
    this.useGlobalReminder = true,
    this.reminderMinutesGlobal = 15,
    this.reminderMinutesFajr = 15,
    this.reminderMinutesDhuhr = 15,
    this.reminderMinutesAsr = 15,
    this.reminderMinutesMaghrib = 15,
    this.reminderMinutesIsha = 15,
    this.notifyPostPrayerDhikr = true,
    this.postPrayerDhikrDelayMinutes = 5,
  });

  /// Resolve the reminder lead time (minutes) for a given prayer name.
  /// Returns 0 if reminders are disabled for that prayer.
  int reminderMinutesFor(String prayerName) {
    if (useGlobalReminder) return reminderMinutesGlobal;
    switch (prayerName) {
      case 'Fajr':
        return reminderMinutesFajr;
      case 'Dhuhr':
        return reminderMinutesDhuhr;
      case 'Asr':
        return reminderMinutesAsr;
      case 'Maghrib':
        return reminderMinutesMaghrib;
      case 'Isha':
        return reminderMinutesIsha;
      default:
        return 0;
    }
  }

  /// Get the UTC offset as Duration, or null if not set.
  Duration? get utcOffset =>
      utcOffsetHours != null ? Duration(minutes: (utcOffsetHours! * 60).round()) : null;

  AppSettingsState copyWith({
    double? fontSize,
    String? calculationMethod,
    ThemeMode? themeMode,
    String? themeColorId,
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
    bool? useGlobalReminder,
    int? reminderMinutesGlobal,
    int? reminderMinutesFajr,
    int? reminderMinutesDhuhr,
    int? reminderMinutesAsr,
    int? reminderMinutesMaghrib,
    int? reminderMinutesIsha,
    bool? notifyPostPrayerDhikr,
    int? postPrayerDhikrDelayMinutes,
  }) {
    return AppSettingsState(
      fontSize: fontSize ?? this.fontSize,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      themeMode: themeMode ?? this.themeMode,
      themeColorId: themeColorId ?? this.themeColorId,
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
      useGlobalReminder: useGlobalReminder ?? this.useGlobalReminder,
      reminderMinutesGlobal:
          reminderMinutesGlobal ?? this.reminderMinutesGlobal,
      reminderMinutesFajr: reminderMinutesFajr ?? this.reminderMinutesFajr,
      reminderMinutesDhuhr: reminderMinutesDhuhr ?? this.reminderMinutesDhuhr,
      reminderMinutesAsr: reminderMinutesAsr ?? this.reminderMinutesAsr,
      reminderMinutesMaghrib:
          reminderMinutesMaghrib ?? this.reminderMinutesMaghrib,
      reminderMinutesIsha: reminderMinutesIsha ?? this.reminderMinutesIsha,
      notifyPostPrayerDhikr:
          notifyPostPrayerDhikr ?? this.notifyPostPrayerDhikr,
      postPrayerDhikrDelayMinutes:
          postPrayerDhikrDelayMinutes ?? this.postPrayerDhikrDelayMinutes,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettingsState> {
  final StorageService _storage;
  final AdhanAudioService _adhanAudio;

  SettingsNotifier(this._storage, {AdhanAudioService? adhanAudio})
      : _adhanAudio = adhanAudio ?? AdhanAudioService.instance,
        super(const AppSettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final fontSize = _storage.getSetting<double>('fontSize', defaultValue: 22.0) ?? 22.0;
    final method =
        _storage.getSetting<String>('calculationMethod', defaultValue: 'UmmAlQura') ??
            'UmmAlQura';
    final themeColorId =
        _storage.getSetting<String>('themeColorId', defaultValue: 'green') ?? 'green';
    // Sync the global palette singleton early so first-frame widgets pick it up.
    ActivePalette.set(AppPalettes.byId(themeColorId));
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
        _storage.getSetting<String>('adhanReciterId', defaultValue: 'adhan1') ?? 'adhan1';
    final playAdhan = _storage.getSetting<bool>('playAdhan', defaultValue: true) ?? true;

    // Pre-prayer reminder settings
    final useGlobalReminder =
        _storage.getSetting<bool>('useGlobalReminder', defaultValue: true) ??
            true;
    final reminderMinutesGlobal = _storage.getSetting<int>(
            'reminderMinutesGlobal',
            defaultValue: 15) ??
        15;
    final reminderMinutesFajr =
        _storage.getSetting<int>('reminderMinutesFajr', defaultValue: 15) ?? 15;
    final reminderMinutesDhuhr =
        _storage.getSetting<int>('reminderMinutesDhuhr', defaultValue: 15) ?? 15;
    final reminderMinutesAsr =
        _storage.getSetting<int>('reminderMinutesAsr', defaultValue: 15) ?? 15;
    final reminderMinutesMaghrib = _storage.getSetting<int>(
            'reminderMinutesMaghrib',
            defaultValue: 15) ??
        15;
    final reminderMinutesIsha =
        _storage.getSetting<int>('reminderMinutesIsha', defaultValue: 15) ?? 15;
    final notifyPostPrayerDhikr = _storage.getSetting<bool>(
            'notifyPostPrayerDhikr',
            defaultValue: true) ??
        true;
    final postPrayerDhikrDelayMinutes = _storage.getSetting<int>(
            'postPrayerDhikrDelayMinutes',
            defaultValue: 5) ??
        5;

    state = AppSettingsState(
      fontSize: fontSize,
      calculationMethod: method,
      themeMode: ThemeMode.light,
      themeColorId: themeColorId,
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
      useGlobalReminder: useGlobalReminder,
      reminderMinutesGlobal: reminderMinutesGlobal,
      reminderMinutesFajr: reminderMinutesFajr,
      reminderMinutesDhuhr: reminderMinutesDhuhr,
      reminderMinutesAsr: reminderMinutesAsr,
      reminderMinutesMaghrib: reminderMinutesMaghrib,
      reminderMinutesIsha: reminderMinutesIsha,
      notifyPostPrayerDhikr: notifyPostPrayerDhikr,
      postPrayerDhikrDelayMinutes: postPrayerDhikrDelayMinutes,
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

  /// Switch the app's accent palette. Updates the global [ActivePalette] so
  /// every `AppColors.primary`/`secondary` getter reflects the change, then
  /// rebuilds [state] so [MaterialApp] picks up a new theme.
  Future<void> setThemeColor(String paletteId) async {
    if (state.themeColorId == paletteId) return;
    ActivePalette.set(AppPalettes.byId(paletteId));
    state = state.copyWith(themeColorId: paletteId);
    await _storage.putSetting('themeColorId', paletteId);
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
      useGlobalReminder: state.useGlobalReminder,
      reminderMinutesGlobal: state.reminderMinutesGlobal,
      reminderMinutesFajr: state.reminderMinutesFajr,
      reminderMinutesDhuhr: state.reminderMinutesDhuhr,
      reminderMinutesAsr: state.reminderMinutesAsr,
      reminderMinutesMaghrib: state.reminderMinutesMaghrib,
      reminderMinutesIsha: state.reminderMinutesIsha,
      notifyPostPrayerDhikr: state.notifyPostPrayerDhikr,
      postPrayerDhikrDelayMinutes: state.postPrayerDhikrDelayMinutes,
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
    if (state.adhanReciterId == reciterId) return;
    // Drop the cached MP3s for the previous reciter so the next reschedule
    // re-downloads the newly selected reciter's audio for both notification
    // tap-playback and the native alarm-triggered playback.
    await _adhanAudio.clearCache();
    state = state.copyWith(adhanReciterId: reciterId);
    await _storage.putSetting('adhanReciterId', reciterId);
  }

  Future<void> setPlayAdhan(bool value) async {
    state = state.copyWith(playAdhan: value);
    await _storage.putSetting('playAdhan', value);
  }

  Future<void> setUseGlobalReminder(bool value) async {
    state = state.copyWith(useGlobalReminder: value);
    await _storage.putSetting('useGlobalReminder', value);
  }

  Future<void> setReminderMinutes(String prayer, int minutes) async {
    switch (prayer) {
      case 'global':
        state = state.copyWith(reminderMinutesGlobal: minutes);
        await _storage.putSetting('reminderMinutesGlobal', minutes);
      case 'fajr':
        state = state.copyWith(reminderMinutesFajr: minutes);
        await _storage.putSetting('reminderMinutesFajr', minutes);
      case 'dhuhr':
        state = state.copyWith(reminderMinutesDhuhr: minutes);
        await _storage.putSetting('reminderMinutesDhuhr', minutes);
      case 'asr':
        state = state.copyWith(reminderMinutesAsr: minutes);
        await _storage.putSetting('reminderMinutesAsr', minutes);
      case 'maghrib':
        state = state.copyWith(reminderMinutesMaghrib: minutes);
        await _storage.putSetting('reminderMinutesMaghrib', minutes);
      case 'isha':
        state = state.copyWith(reminderMinutesIsha: minutes);
        await _storage.putSetting('reminderMinutesIsha', minutes);
    }
  }

  Future<void> setNotifyPostPrayerDhikr(bool value) async {
    state = state.copyWith(notifyPostPrayerDhikr: value);
    await _storage.putSetting('notifyPostPrayerDhikr', value);
  }

  Future<void> setPostPrayerDhikrDelayMinutes(int minutes) async {
    state = state.copyWith(postPrayerDhikrDelayMinutes: minutes);
    await _storage.putSetting('postPrayerDhikrDelayMinutes', minutes);
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

}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsState>((ref) {
  return SettingsNotifier(
    ref.watch(storageServiceProvider),
    adhanAudio: ref.watch(adhanAudioServiceProvider),
  );
});

/// Currently active palette derived from the persisted [themeColorId].
/// Watching this rebuilds [MaterialApp.theme] when the user picks a color.
final activePaletteProvider = Provider<ThemePalette>((ref) {
  final id = ref.watch(settingsProvider.select((s) => s.themeColorId));
  final palette = AppPalettes.byId(id);
  // Keep the global singleton in sync so non-Riverpod call sites
  // (`AppColors.primary`, etc.) see the same palette.
  ActivePalette.set(palette);
  return palette;
});
