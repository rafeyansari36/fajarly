import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/alarm_diagnostics.dart';

final _diagnosticsReportProvider = FutureProvider<DiagnosticsReport>((_) {
  return const AlarmDiagnostics().check();
});

/// Red banner that only appears when a system permission is blocking alarms
/// from firing on the lock screen. Tapping it opens the diagnostics screen
/// with a fix-button next to each missing permission.
class DiagnosticsBanner extends ConsumerWidget {
  const DiagnosticsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(_diagnosticsReportProvider);
    final ready = report.valueOrNull?.alarmWillFireOnLockScreen ?? true;
    if (ready) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await context.push('/diagnostics');
            ref.invalidate(_diagnosticsReportProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: scheme.onErrorContainer, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alarms may not fire on the lock screen',
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to open diagnostics and fix permissions',
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onErrorContainer),
            ]),
          ),
        ),
      ),
    );
  }
}
