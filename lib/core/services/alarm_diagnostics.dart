import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime check + deep-link into the system settings page for every
/// permission / OS switch that can block an alarm from firing. Wraps the
/// `fajarly/secure` native channel for platform-specific Settings intents
/// that `permission_handler` doesn't expose directly.
class AlarmDiagnostics {
  const AlarmDiagnostics();

  static const _channel = MethodChannel('fajarly/secure');

  Future<DiagnosticsReport> check() async {
    final notification = await Permission.notification.isGranted;
    final camera = await Permission.camera.isGranted;
    final exactAlarm = await _call<bool>('canScheduleExactAlarms') ?? false;
    final fullScreenIntent = await _call<bool>('canUseFullScreenIntent') ?? false;
    final batteryUnrestricted =
        await _call<bool>('isIgnoringBatteryOptimizations') ?? false;
    return DiagnosticsReport(
      notification: notification,
      exactAlarm: exactAlarm,
      fullScreenIntent: fullScreenIntent,
      batteryUnrestricted: batteryUnrestricted,
      camera: camera,
    );
  }

  Future<void> openNotificationSettings() => _call<void>('openNotificationSettings');
  Future<void> openExactAlarmSettings() => _call<void>('openExactAlarmSettings');
  Future<void> openFullScreenIntentSettings() =>
      _call<void>('openFullScreenIntentSettings');
  Future<void> openBatteryOptimizationSettings() =>
      _call<void>('openBatteryOptimizationSettings');
  Future<void> openAppSettings() => _call<void>('openAppSettings');

  Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<T?> _call<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

class DiagnosticsReport {
  const DiagnosticsReport({
    required this.notification,
    required this.exactAlarm,
    required this.fullScreenIntent,
    required this.batteryUnrestricted,
    required this.camera,
  });

  final bool notification;
  final bool exactAlarm;
  final bool fullScreenIntent;
  final bool batteryUnrestricted;
  final bool camera;

  bool get alarmWillFireOnLockScreen =>
      notification && exactAlarm && fullScreenIntent && batteryUnrestricted;

  bool get allGreen => alarmWillFireOnLockScreen && camera;
}
