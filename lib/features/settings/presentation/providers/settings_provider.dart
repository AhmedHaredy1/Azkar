import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';

class AppSettingsState {
  final double fontSize;
  final String calculationMethod;

  const AppSettingsState({
    this.fontSize = 22.0,
    this.calculationMethod = 'UmmAlQura',
  });

  AppSettingsState copyWith({
    double? fontSize,
    String? calculationMethod,
  }) {
    return AppSettingsState(
      fontSize: fontSize ?? this.fontSize,
      calculationMethod: calculationMethod ?? this.calculationMethod,
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
    state = AppSettingsState(fontSize: fontSize, calculationMethod: method);
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _storage.putSetting('fontSize', size);
  }

  Future<void> setCalculationMethod(String method) async {
    state = state.copyWith(calculationMethod: method);
    await _storage.putSetting('calculationMethod', method);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsState>((ref) {
  return SettingsNotifier(StorageService.instance);
});
