import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/services/secure_screen.dart';
import '../../../scanner/domain/entities/scanned_code.dart';
import '../../../scanner/presentation/providers/scanner_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../streaks/presentation/providers/streak_providers.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/entities/difficulty.dart';
import '../providers/alarm_providers.dart';

class RingingScreen extends ConsumerStatefulWidget {
  const RingingScreen({required this.alarmId, super.key});
  final int alarmId;

  @override
  ConsumerState<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends ConsumerState<RingingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: true,
  );
  final _secure = const SecureScreen();
  late AnimationController _pulse;
  final DateTime _openedAt = DateTime.now();
  bool _stopping = false;
  int _scansNeeded = 1;
  int _scansDone = 0;
  Alarm? _alarm;
  int _snoozeCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _secure.enable();
    _secure.dismissKeyguard();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _loadAlarm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If Android pauses us (home button, swipe, notification shade) while
    // the alarm is still ringing, yank the activity back to the front.
    if (_stopping) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _secure.bringToFront();
    }
  }

  Future<void> _loadAlarm() async {
    final alarm = await ref.read(alarmRepositoryProvider).getById(widget.alarmId);
    if (!mounted || alarm == null) return;
    final prefs = ref.read(settingsPrefsProvider);
    final snoozeCount = prefs.snoozeCountFor(alarm.id);
    setState(() {
      _alarm = alarm;
      _snoozeCount = snoozeCount;
      _scansNeeded = _computeScansNeeded(alarm.difficulty, snoozeCount);
    });
  }

  int _computeScansNeeded(Difficulty d, int snoozeCount) {
    final base = switch (d) {
      Difficulty.one => 1,
      Difficulty.two => 2,
      Difficulty.escalating => 1,
    };
    // Every snooze adds one scan. Escalating doubles on top of that.
    if (d == Difficulty.escalating) {
      return base + snoozeCount * 2;
    }
    return base + snoozeCount;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_stopping || _alarm == null) return;
    final alarm = _alarm!;
    final matcher = ref.read(matchCodeUseCaseProvider);

    for (final b in capture.barcodes) {
      final scanned = ScannedCode(value: b.rawValue, formatName: b.format.name);
      if (matcher(scanned: scanned, expected: alarm.expectedCode)) {
        setState(() => _scansDone++);
        if (_scansDone >= _scansNeeded) {
          await _stop(alarm);
          return;
        }
        await _controller.stop();
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        await _controller.start();
        return;
      }
    }
  }

  Future<void> _stop(Alarm alarm) async {
    _stopping = true;
    final now = DateTime.now();
    final secondsToScan = now.difference(_openedAt).inSeconds;
    await ref.read(streakRepositoryProvider).recordWakeUp(
          alarmId: alarm.id,
          scannedAt: now,
          secondsToScan: secondsToScan,
        );
    await ref.read(settingsPrefsProvider).clearSnoozeCount(alarm.id);
    await ref.read(alarmSchedulerProvider).stopRinging(widget.alarmId);
    if (!alarm.isOneShot && alarm.enabled) {
      await ref.read(alarmSchedulerProvider).schedule(alarm);
    }
    if (mounted) context.go('/');
  }

  Future<void> _snooze() async {
    if (_stopping || _alarm == null) return;
    _stopping = true;
    final alarm = _alarm!;
    final minutes = ref.read(snoozeMinutesProvider);
    final fireAt = DateTime.now().add(Duration(minutes: minutes));
    await ref.read(settingsPrefsProvider).incrementSnoozeCount(alarm.id);
    await ref.read(alarmSchedulerProvider).stopRinging(alarm.id);
    await ref.read(alarmSchedulerProvider).scheduleSnooze(alarm, fireAt);
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _secure.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pulse.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarm = _alarm;
    final snoozeMinutes = ref.watch(snoozeMinutesProvider);
    final canSnooze = alarm?.snoozeEnabled ?? false;
    final nextPenalty =
        alarm == null ? 0 : _computeScansNeeded(alarm.difficulty, _snoozeCount + 1);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => IgnorePointer(
              child: Container(
                color: Colors.red.withOpacity(0.10 + 0.15 * _pulse.value),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WAKE UP',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          )),
                  const SizedBox(height: 8),
                  Text(
                    'Scan your unlock code to stop the alarm ($_scansDone / $_scansNeeded)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  if (_snoozeCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Snooze penalty active · $_snoozeCount snooze${_snoozeCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  const Spacer(),
                  if (canSnooze)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _stopping ? null : _snooze,
                        icon: const Icon(Icons.snooze),
                        label: Text(
                          'Snooze $snoozeMinutes min  ·  next unlock: $nextPenalty scans',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
