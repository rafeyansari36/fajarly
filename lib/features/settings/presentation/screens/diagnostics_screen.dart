import 'package:alarm/alarm.dart' as pkg;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/alarm_diagnostics.dart';

final _diagnosticsProvider = Provider((_) => const AlarmDiagnostics());

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen>
    with WidgetsBindingObserver {
  DiagnosticsReport? _report;
  bool _loading = false;
  bool _firingTest = false;

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
    // Re-check after the user returns from a system settings page.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final report = await ref.read(_diagnosticsProvider).check();
    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  Future<void> _fireTest() async {
    setState(() => _firingTest = true);
    final when = DateTime.now().add(const Duration(seconds: 10));
    await pkg.Alarm.set(
      alarmSettings: pkg.AlarmSettings(
        id: 99999,
        dateTime: when,
        assetAudioPath: 'assets/audio/alarm.mp3',
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        volumeSettings: pkg.VolumeSettings.fade(
          volume: 0.9,
          fadeDuration: const Duration(seconds: 2),
        ),
        notificationSettings: const pkg.NotificationSettings(
          title: 'Fajarly Pro — Test',
          body: 'This is a 10-second test alarm. Lock your phone now.',
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _firingTest = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test alarm scheduled for 10 seconds from now. Lock your screen.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final diag = ref.read(_diagnosticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: _loading && report == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(report: report),
                const SizedBox(height: 16),
                _CheckTile(
                  label: 'Notifications',
                  subtitle: 'Post alarm notifications',
                  granted: report?.notification ?? false,
                  onFix: () async {
                    final granted = await diag.requestNotification();
                    if (!granted) await diag.openNotificationSettings();
                    await _refresh();
                  },
                ),
                _CheckTile(
                  label: 'Exact alarm',
                  subtitle: 'Fire at precisely the scheduled time',
                  granted: report?.exactAlarm ?? false,
                  onFix: () async {
                    await diag.openExactAlarmSettings();
                  },
                ),
                _CheckTile(
                  label: 'Full-screen notifications',
                  subtitle: 'Launch over the lock screen (Android 14+)',
                  granted: report?.fullScreenIntent ?? false,
                  onFix: () async {
                    await diag.openFullScreenIntentSettings();
                  },
                ),
                _CheckTile(
                  label: 'Battery optimization off',
                  subtitle: 'Keep the alarm alive in deep sleep',
                  granted: report?.batteryUnrestricted ?? false,
                  onFix: () async {
                    await diag.openBatteryOptimizationSettings();
                  },
                ),
                _CheckTile(
                  label: 'Display pop-up while in background',
                  subtitle:
                      'Lets the alarm draw over whatever you\'re doing — opens the per-app switch on MIUI / OxygenOS / ColorOS / FuntouchOS',
                  granted: report?.displayOverApps ?? false,
                  onFix: () async {
                    await diag.openOemPermissionEditor();
                  },
                ),
                _CheckTile(
                  label: 'Camera',
                  subtitle: 'Scan the unlock code',
                  granted: report?.camera ?? false,
                  onFix: () async {
                    final granted = await diag.requestCamera();
                    if (!granted) await diag.openAppSettings();
                    await _refresh();
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                Text('Test the alarm',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Schedules an alarm 10 seconds from now. Lock your phone '
                  'before it fires to verify the full-screen ringing screen '
                  'really opens on the lock screen.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _firingTest ? null : _fireTest,
                  icon: const Icon(Icons.alarm_on),
                  label: Text(_firingTest ? 'Scheduling…' : 'Fire test alarm (10s)'),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.report});
  final DiagnosticsReport? report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ready = report?.alarmWillFireOnLockScreen ?? false;
    return Card(
      color: ready ? scheme.primaryContainer : scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Icon(
            ready ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 40,
            color: ready ? scheme.onPrimaryContainer : scheme.onErrorContainer,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready
                      ? 'Your alarm will fire on the lock screen'
                      : 'One or more permissions are blocking alarms',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ready
                            ? scheme.onPrimaryContainer
                            : scheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  ready
                      ? 'Full-screen intent, exact alarm, notifications, and battery are all granted.'
                      : 'Tap “Fix” below next to any red item to open the right system settings page.',
                  style: TextStyle(
                    color: ready
                        ? scheme.onPrimaryContainer
                        : scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.label,
    required this.subtitle,
    required this.granted,
    required this.onFix,
  });
  final String label;
  final String subtitle;
  final bool granted;
  final Future<void> Function() onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                granted ? Icons.check_circle : Icons.cancel,
                color: granted ? scheme.primary : scheme.error,
                size: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!granted)
                FilledButton.tonal(
                  onPressed: onFix,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Fix'),
                )
              else
                Text(
                  'OK',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
