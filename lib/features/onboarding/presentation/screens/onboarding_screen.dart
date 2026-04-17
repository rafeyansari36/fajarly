import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/alarm_diagnostics.dart';
import '../providers/onboarding_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _lastPage = 4;   // 0 welcome, 1 concept, 2 perms, 3 background, 4 autostart

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // Before finishing, check whether the permissions that block the alarm
    // from firing on the lock screen are actually granted. If the user
    // skipped them, warn them explicitly — this is the feedback loop the
    // user asked for.
    final report = await const AlarmDiagnostics().check();
    if (!mounted) return;

    if (!report.alarmWillFireOnLockScreen) {
      final proceed = await _showBlockingPermissionWarning(report);
      if (!mounted || proceed != true) return;
    }

    await ref.read(onboardingPrefsProvider).markCompleted();
    if (!mounted) return;
    context.go('/');
  }

  Future<bool?> _showBlockingPermissionWarning(DiagnosticsReport r) {
    final missing = <String>[
      if (!r.notification) 'Notifications',
      if (!r.exactAlarm) 'Exact alarm',
      if (!r.fullScreenIntent) 'Full-screen notifications',
      if (!r.batteryUnrestricted) 'Background (battery unrestricted)',
    ];
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(dialogCtx).colorScheme.error, size: 48),
        title: const Text('Alarms will not work reliably'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Without these permissions, the alarm will not fire when your phone is locked:',
            ),
            const SizedBox(height: 12),
            for (final m in missing)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.cancel, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m)),
                ]),
              ),
            const SizedBox(height: 12),
            const Text(
              'You can fix this right now or later from Settings → Alarm diagnostics.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Continue anyway'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Go back & fix'),
          ),
        ],
      ),
    );
  }

  void _goNext() {
    if (_page == _lastPage) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Indicators(page: _page, count: _lastPage + 1),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _goNext,
                    child: const Text('Next'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _controller,
          onPageChanged: (i) => setState(() => _page = i),
          children: const [
            _WelcomeSlide(),
            _ConceptSlide(),
            _PermissionsSlide(),
            _BackgroundSlide(),
            _AutostartSlide(),
          ],
        ),
      ),
    );
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.page, required this.count});
  final int page;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 28 : 8,
          decoration: BoxDecoration(
            color: active ? scheme.primary : scheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _SlideShell extends StatelessWidget {
  const _SlideShell({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(title, style: t.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text(body, style: t.bodyLarge?.copyWith(height: 1.5)),
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Image.asset('assets/branding/logo.png', height: 200),
          const SizedBox(height: 8),
          Text(
            'Welcome to Fajarly',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'A smart alarm that will not let you stay in bed. To stop it, you have to get up and scan a barcode or QR code.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ConceptSlide extends StatelessWidget {
  const _ConceptSlide();
  @override
  Widget build(BuildContext context) {
    return const _SlideShell(
      icon: Icons.qr_code_scanner,
      title: 'Any QR or barcode',
      body:
          'Use the barcode on your shampoo bottle, a book, a product in your kitchen, or print your own QR or Code-128 barcode and stick it far from your bed. You set the rule.',
    );
  }
}

class _PermissionsSlide extends ConsumerStatefulWidget {
  const _PermissionsSlide();
  @override
  ConsumerState<_PermissionsSlide> createState() => _PermissionsSlideState();
}

class _PermissionsSlideState extends ConsumerState<_PermissionsSlide> {
  bool _notif = false;
  bool _exact = false;
  bool _camera = false;
  bool _requesting = false;

  Future<void> _requestAll() async {
    setState(() => _requesting = true);
    final results = await [
      Permission.notification,
      Permission.scheduleExactAlarm,
      Permission.camera,
    ].request();
    if (!mounted) return;
    setState(() {
      _notif = results[Permission.notification]?.isGranted ?? false;
      _exact = results[Permission.scheduleExactAlarm]?.isGranted ?? false;
      _camera = results[Permission.camera]?.isGranted ?? false;
      _requesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SlideShell(
      icon: Icons.shield_outlined,
      title: 'Grant permissions',
      body:
          'Notifications and exact alarms are required for the alarm to fire on time. Camera is needed to scan your unlock code.',
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PermRow(label: 'Notifications', granted: _notif),
          _PermRow(label: 'Exact alarm', granted: _exact),
          _PermRow(label: 'Camera', granted: _camera),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _requesting ? null : _requestAll,
            child: Text(_requesting ? 'Requesting…' : 'Grant permissions'),
          ),
        ],
      ),
    );
  }
}

class _BackgroundSlide extends ConsumerStatefulWidget {
  const _BackgroundSlide();
  @override
  ConsumerState<_BackgroundSlide> createState() => _BackgroundSlideState();
}

class _BackgroundSlideState extends ConsumerState<_BackgroundSlide>
    with WidgetsBindingObserver {
  bool _granted = false;
  bool _fullScreen = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User comes back from Settings — re-check.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final report = await const AlarmDiagnostics().check();
    if (!mounted) return;
    setState(() {
      _granted = report.batteryUnrestricted;
      _fullScreen = report.fullScreenIntent;
    });
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    // This fires the Android "Allow this app to always run in background?" dialog.
    await Permission.ignoreBatteryOptimizations.request();
    // Also ask the user to grant full-screen notifications (Android 14+).
    await const AlarmDiagnostics().openFullScreenIntentSettings();
    if (!mounted) return;
    setState(() => _requesting = false);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SlideShell(
      icon: Icons.bolt,
      title: 'Allow background running',
      body:
          'Android kills apps aggressively when the phone is idle. Fajarly needs to run in the background so it can fire the alarm even when your screen is locked. Without this, the alarm will NOT ring.',
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PermRow(label: 'Battery unrestricted (background)', granted: _granted),
          _PermRow(label: 'Full-screen notifications', granted: _fullScreen),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _requesting ? null : _request,
            child: Text(_requesting ? 'Opening…' : 'Allow background running'),
          ),
          if (_granted && _fullScreen) ...[
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.check_circle, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text('Your alarm will fire on the lock screen',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
          ],
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({required this.label, required this.granted});
  final String label;
  final bool granted;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(
          granted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: granted ? scheme.primary : scheme.outline,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ]),
    );
  }
}

class _AutostartSlide extends ConsumerWidget {
  const _AutostartSlide();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manufacturerAsync = ref.watch(manufacturerProvider);
    final oem = ref.watch(oemAutostartProvider);

    return manufacturerAsync.maybeWhen(
      data: (m) {
        final hasMapping = oem.hasMappingFor(m);
        return _SlideShell(
          icon: Icons.power_settings_new,
          title: 'Autostart (manufacturer)',
          body: hasMapping
              ? 'Your device (${m!}) has a separate autostart switch that Android itself can\'t control. Turn Fajarly on there so alarms fire after your phone has been idle overnight.'
              : 'Some manufacturers add extra kill-switches on top of Android\'s battery settings. If alarms still don\'t fire reliably, look for an "Autostart" option in your phone\'s settings.',
          action: hasMapping
              ? FilledButton.tonal(
                  onPressed: () => oem.openAutostartSettings(m!),
                  child: const Text('Open autostart settings'),
                )
              : null,
        );
      },
      orElse: () => const _SlideShell(
        icon: Icons.power_settings_new,
        title: 'Autostart (manufacturer)',
        body:
            'Some manufacturers add extra kill-switches on top of Android\'s battery settings. If alarms still don\'t fire reliably, look for an "Autostart" option in your phone\'s settings.',
      ),
    );
  }
}
