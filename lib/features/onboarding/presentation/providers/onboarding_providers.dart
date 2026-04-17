import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/utils/oem_autostart.dart';
import '../../data/onboarding_prefs.dart';

final prefsBoxProvider = Provider<Box<dynamic>>((_) {
  return Hive.box<dynamic>('prefs');
});

final onboardingPrefsProvider = Provider<OnboardingPrefs>((ref) {
  return OnboardingPrefs(ref.watch(prefsBoxProvider));
});

final onboardingCompletedStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(onboardingPrefsProvider).watch();
});

final oemAutostartProvider = Provider<OemAutostart>((_) {
  return const OemAutostart();
});

final manufacturerProvider = FutureProvider<String?>((ref) {
  return ref.watch(oemAutostartProvider).detectManufacturer();
});
