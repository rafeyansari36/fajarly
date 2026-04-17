import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  ThemeMode toFlutter() => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };
  String get label => switch (this) {
        AppThemeMode.system => 'System',
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
      };
}

class SettingsPrefs {
  SettingsPrefs(this._box);
  final Box<dynamic> _box;

  static const _keyTheme = 'theme_mode';
  static const _keySnoozeMinutes = 'default_snooze_minutes';

  static const defaultSnoozeMinutes = 5;
  static const minSnoozeMinutes = 1;
  static const maxSnoozeMinutes = 15;

  AppThemeMode get themeMode {
    final raw = _box.get(_keyTheme, defaultValue: 'system') as String;
    return AppThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _box.put(_keyTheme, mode.name);

  int get snoozeMinutes =>
      _box.get(_keySnoozeMinutes, defaultValue: defaultSnoozeMinutes) as int;

  Future<void> setSnoozeMinutes(int m) {
    final clamped = m.clamp(minSnoozeMinutes, maxSnoozeMinutes);
    return _box.put(_keySnoozeMinutes, clamped);
  }

  /// Per-alarm snooze counter — increments on snooze, cleared on successful
  /// stop. Used by the ringing screen to apply the scan-count penalty.
  int snoozeCountFor(int alarmId) =>
      _box.get('snooze_count_$alarmId', defaultValue: 0) as int;

  Future<void> incrementSnoozeCount(int alarmId) =>
      _box.put('snooze_count_$alarmId', snoozeCountFor(alarmId) + 1);

  Future<void> clearSnoozeCount(int alarmId) =>
      _box.delete('snooze_count_$alarmId');

  Stream<void> watchAll() => _box.watch().map((_) {});
}
