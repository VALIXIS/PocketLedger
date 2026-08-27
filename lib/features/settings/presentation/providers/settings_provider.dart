import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class SettingsState {
  final String currency;
  final ThemeMode themeMode;

  SettingsState({required this.currency, required this.themeMode});

  SettingsState copyWith({String? currency, ThemeMode? themeMode}) {
    return SettingsState(
      currency: currency ?? this.currency,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String boxName = 'settings_box';

  SettingsNotifier()
    : super(SettingsState(currency: 'USD', themeMode: ThemeMode.light)) {
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final box = Hive.box(boxName);
      final currency = box.get('currency', defaultValue: 'USD') as String;
      final themeIndex =
          box.get('themeMode', defaultValue: 1) as int; // 1 = light, 2 = dark
      ThemeMode mode;
      if (themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        mode = ThemeMode.values[themeIndex];
      } else {
        mode = ThemeMode.light;
      }
      state = SettingsState(currency: currency, themeMode: mode);
    } catch (_) {
      // Safe fallback if Hive box is not yet opened or errors
      state = SettingsState(currency: 'USD', themeMode: ThemeMode.light);
    }
  }

  Future<void> setCurrency(String currency) async {
    final box = Hive.box(boxName);
    await box.put('currency', currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final box = Hive.box(boxName);
    await box.put('themeMode', themeMode.index);
    state = state.copyWith(themeMode: themeMode);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
