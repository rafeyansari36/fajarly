import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alarm/presentation/screens/add_edit_alarm_screen.dart';
import '../../features/alarm/presentation/screens/home_screen.dart';
import '../../features/alarm/presentation/screens/ringing_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/qr_generator/presentation/screens/qr_generator_screen.dart';
import '../../features/scanner/presentation/screens/barcode_setup_screen.dart';
import '../../features/settings/presentation/screens/diagnostics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/streaks/presentation/screens/streaks_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _BoolStreamListenable(
      ref.watch(onboardingCompletedStreamProvider.stream),
    ),
    redirect: (context, state) {
      final completed = ref.read(onboardingPrefsProvider).isCompleted;
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!completed && !atOnboarding) return '/onboarding';
      if (completed && atOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: '/alarm/new',
        builder: (_, __) => const AddEditAlarmScreen(),
      ),
      GoRoute(
        path: '/alarm/edit/:id',
        builder: (_, state) => AddEditAlarmScreen(
          alarmId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/scanner/setup',
        builder: (_, __) => const BarcodeSetupScreen(),
      ),
      GoRoute(
        path: '/qr/generate',
        builder: (_, state) => QrGeneratorScreen(
          returnAsCode: state.uri.queryParameters['pickable'] == 'true',
        ),
      ),
      GoRoute(
        path: '/streaks',
        builder: (_, __) => const StreaksScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/diagnostics',
        builder: (_, __) => const DiagnosticsScreen(),
      ),
      GoRoute(
        path: '/ringing/:id',
        builder: (_, state) => RingingScreen(
          alarmId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
});

/// Adapter so GoRouter can refresh redirects when a stream emits.
class _BoolStreamListenable extends ChangeNotifier {
  _BoolStreamListenable(Stream<bool> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<bool> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
