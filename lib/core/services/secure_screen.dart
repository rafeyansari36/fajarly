import 'package:flutter/services.dart';

/// Thin wrapper around the `fajarly/secure` method channel wired in
/// MainActivity.kt. Two jobs:
///
/// - toggle FLAG_SECURE so screenshots / recents previews are blocked while
///   the alarm is ringing (prevents faking a scan from a saved screen cap);
/// - ask the native side to relaunch MainActivity to the front whenever
///   Android pauses our activity during an active ring. Together with
///   showWhenLocked / turnScreenOn / dismissKeyguard flags in MainActivity,
///   this is as close to "you cannot leave" as Android lets an app get
///   without SYSTEM_ALERT_WINDOW.
class SecureScreen {
  const SecureScreen();

  static const _channel = MethodChannel('fajarly/secure');

  Future<void> enable() => _invoke('setSecure', true);
  Future<void> disable() => _invoke('setSecure', false);

  Future<void> bringToFront() => _invoke('bringToFront', null);

  Future<void> dismissKeyguard() => _invoke('dismissKeyguard', null);

  Future<void> _invoke(String method, Object? arg) async {
    try {
      await _channel.invokeMethod<void>(method, arg);
    } on MissingPluginException {
      // Non-Android host (tests, iOS). Silent.
    } on PlatformException {
      // Best-effort; don't break the alarm flow over a platform hiccup.
    }
  }
}
