import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../data/settings_prefs.dart';

final settingsPrefsProvider = Provider<SettingsPrefs>((ref) {
  return SettingsPrefs(ref.watch(prefsBoxProvider));
});

/// Stream that emits on any change to the prefs box so widgets watching theme
/// or snooze duration rebuild without manual invalidation.
final settingsTickProvider = StreamProvider<void>((ref) {
  return ref.watch(settingsPrefsProvider).watchAll();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  ref.watch(settingsTickProvider);
  return ref.watch(settingsPrefsProvider).themeMode.toFlutter();
});

final snoozeMinutesProvider = Provider<int>((ref) {
  ref.watch(settingsTickProvider);
  return ref.watch(settingsPrefsProvider).snoozeMinutes;
});
