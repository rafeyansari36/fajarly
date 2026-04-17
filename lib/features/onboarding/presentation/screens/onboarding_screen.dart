import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/onboarding_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _lastPage = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingPrefsProvider).markCompleted();
    if (!mounted) return;
    context.go('/');
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
    // SingleChildScrollView guards against overflow on very small phones; the
    // bottom CTA lives in Scaffold.bottomNavigationBar and is always visible.
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
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
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

    // Fall back to a static slide immediately if the manufacturer lookup
    // hasn't resolved — we don't want a spinner hiding the slide content.
    return manufacturerAsync.maybeWhen(
      data: (m) {
        final hasMapping = oem.hasMappingFor(m);
        return _SlideShell(
          icon: Icons.battery_charging_full,
          title: 'Keep the alarm alive',
          body: hasMapping
              ? 'Your device (${m!}) aggressively kills background apps. Allow Fajarly to autostart so alarms still fire after the phone has been idle. You can always change this later in Settings.'
              : 'Exclude Fajarly from battery optimization in system Settings so alarms fire reliably after the phone has been idle. You can always open it from Settings later.',
          action: hasMapping
              ? FilledButton.tonal(
                  onPressed: () => oem.openAutostartSettings(m!),
                  child: const Text('Open autostart settings'),
                )
              : null,
        );
      },
      orElse: () => const _SlideShell(
        icon: Icons.battery_charging_full,
        title: 'Keep the alarm alive',
        body:
            'Exclude Fajarly from battery optimization in system Settings so alarms fire reliably after the phone has been idle. You can always open it from Settings later.',
      ),
    );
  }
}
