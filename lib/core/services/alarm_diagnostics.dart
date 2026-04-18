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
    final displayOverApps = await _call<bool>('canDrawOverlays') ?? false;
    return DiagnosticsReport(
      notification: notification,
      exactAlarm: exactAlarm,
      fullScreenIntent: fullScreenIntent,
      batteryUnrestricted: batteryUnrestricted,
      displayOverApps: displayOverApps,
      camera: camera,
    );
  }

  Future<void> openNotificationSettings() => _call<void>('openNotificationSettings');
  Future<void> openExactAlarmSettings() => _call<void>('openExactAlarmSettings');
  Future<void> openFullScreenIntentSettings() =>
      _call<void>('openFullScreenIntentSettings');
  Future<void> openBatteryOptimizationSettings() =>
      _call<void>('openBatteryOptimizationSettings');
  Future<void> openOverlaySettings() => _call<void>('openOverlaySettings');

  /// Opens the OEM-specific permission editor (MIUI / ColorOS / FuntouchOS).
  /// This is where the *"Display pop-up windows while running in background"*
  /// switch lives on Xiaomi / Oppo / Vivo — standard Android doesn't have
  /// that exact setting; SYSTEM_ALERT_WINDOW is the closest AOSP equivalent.
  Future<void> openOemPermissionEditor() =>
      _call<void>('openOemPermissionEditor');

  Future<void> openAppSettings() => _call<void>('openAppSettings');

  Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestBatteryUnrestricted() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
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
    required this.displayOverApps,
    required this.camera,
  });

  final bool notification;
  final bool exactAlarm;
  final bool fullScreenIntent;
  final bool batteryUnrestricted;

  /// SYSTEM_ALERT_WINDOW — also known as "Display over other apps" on AOSP
  /// and "Display pop-up windows while running in background" on MIUI.
  final bool displayOverApps;

  final bool camera;

  /// Permissions that are *enforceable* — Android gives us an API to grant
  /// these. If any of these is missing, alarms reliably fail on the lock
  /// screen. The OEM pop-up-in-background switch is deliberately excluded
  /// because it's informational only (no Android API exposes its state, so
  /// blocking on it would cause false negatives on stock ROMs).
  bool get alarmWillFireOnLockScreen =>
      notification && exactAlarm && fullScreenIntent && batteryUnrestricted;

  bool get allGreen => alarmWillFireOnLockScreen && camera && displayOverApps;
}
