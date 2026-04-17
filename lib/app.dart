import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

class FajarlyApp extends ConsumerStatefulWidget {
  const FajarlyApp({super.key});

  @override
  ConsumerState<FajarlyApp> createState() => _FajarlyAppState();
}

class _FajarlyAppState extends ConsumerState<FajarlyApp> {
  @override
  void initState() {
    super.initState();
    // Route the user to the ringing screen whenever an alarm fires.
    Alarm.ringStream.stream.listen((settings) {
      final router = ref.read(routerProvider);
      router.push('/ringing/${settings.id}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Fajarly Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
