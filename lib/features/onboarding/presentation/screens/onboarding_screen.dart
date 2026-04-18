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
          const SizedBox(height: 24),
          // White container so the logo (which has its own white background)
          // looks intentional in dark mode instead of a floating artifact.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.asset('assets/branding/logo.png', height: 180),
          ),
          const SizedBox(height: 24),
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
  bool _autoRequested = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    // Auto-fire the three runtime-permission dialogs the first time the user
    // lands on this slide — no need to tap a button first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoRequestIfNeeded());
  }

  Future<void> _autoRequestIfNeeded() async {
    if (_autoRequested) return;
    _autoRequested = true;
    await _requestAll();
  }

  Future<void> _requestAll() async {
    if (_requesting) return;
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
          'Notifications and exact alarms are required for the alarm to fire on time. Camera is needed to scan your unlock code. We ask for all three automatically — tap Allow on each dialog.',
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PermRow(label: 'Notifications', granted: _notif),
          _PermRow(label: 'Exact alarm', granted: _exact),
          _PermRow(label: 'Camera', granted: _camera),
          if (!_notif || !_exact || !_camera) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _requesting ? null : _requestAll,
              child: Text(_requesting ? 'Requesting…' : 'Re-request permissions'),
            ),
          ],
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
  DiagnosticsReport? _report;
  bool _autoRequested = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh().then((_) => _autoRequestIfNeeded());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final report = await const AlarmDiagnostics().check();
    if (!mounted) return;
    setState(() => _report = report);
  }

  /// On the very first visit, auto-chain the system dialogs so the user
  /// doesn't have to find and tap three Allow buttons. Android requires an
  /// explicit user tap for each — we can't bypass that — but we can at
  /// least make the dialogs appear in sequence without extra UI friction.
  Future<void> _autoRequestIfNeeded() async {
    if (_autoRequested) return;
    _autoRequested = true;
    await _requestAllSequentially();
  }

  Future<void> _requestAllSequentially() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    final diag = const AlarmDiagnostics();

    // 1. Battery unrestricted — this fires the standard Android yes/no dialog.
    if (!(_report?.batteryUnrestricted ?? false)) {
      await diag.requestBatteryUnrestricted();
      await _refresh();
    }

    // 2. Full-screen notifications — opens a Settings page the user must
    //    return from. Only jump there if not already granted.
    if (!(_report?.fullScreenIntent ?? false) && mounted) {
      await diag.openFullScreenIntentSettings();
      // Lifecycle observer will re-refresh when user returns.
    }

    if (mounted) setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = _report;
    final diag = const AlarmDiagnostics();
    final allGreen = r?.alarmWillFireOnLockScreen ?? false;

    return _SlideShell(
      icon: Icons.bolt,
      title: 'Allow background running',
      body:
          'Android kills apps aggressively when idle. Fajarly needs the two switches below to fire the alarm while your phone is locked. We will ask for each one automatically — tap Allow in each dialog.',
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PermActionRow(
            label: 'Battery unrestricted',
            granted: r?.batteryUnrestricted ?? false,
            onAllow: () async {
              await diag.requestBatteryUnrestricted();
              await _refresh();
            },
          ),
          _PermActionRow(
            label: 'Full-screen notifications',
            granted: r?.fullScreenIntent ?? false,
            onAllow: () async {
              await diag.openFullScreenIntentSettings();
            },
          ),
          const SizedBox(height: 20),
          _ManualNote(
            title: 'One more thing — do this manually',
            body:
                'On some phones (Xiaomi, OnePlus, Oppo, Vivo) there is a separate "Display pop-up while in background" switch we can\'t toggle for you. Open system Settings → Apps → Fajarly Pro → Permissions → Other permissions and turn it on.',
          ),
          const SizedBox(height: 16),
          if (!allGreen)
            FilledButton.tonal(
              onPressed: _requesting ? null : _requestAllSequentially,
              child: Text(_requesting
                  ? 'Requesting…'
                  : 'Re-run permission requests'),
            ),
          if (allGreen) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.check_circle, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Your alarm will fire on the lock screen',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _ManualNote extends StatelessWidget {
  const _ManualNote({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: scheme.tertiary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 4),
                Text(body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermActionRow extends StatelessWidget {
  const _PermActionRow({
    required this.label,
    required this.granted,
    required this.onAllow,
  });
  final String label;
  final bool granted;
  final Future<void> Function() onAllow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(
          granted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: granted ? scheme.primary : scheme.outline,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
        if (!granted)
          FilledButton.tonal(
            onPressed: onAllow,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Allow'),
          )
        else
          Text('Granted',
              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
      ]),
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
