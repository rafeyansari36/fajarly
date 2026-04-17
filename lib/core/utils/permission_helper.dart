import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  const PermissionHelper();

  Future<bool> ensureAlarmPermissions() async {
    final results = await [
      Permission.notification,
      Permission.scheduleExactAlarm,
      Permission.ignoreBatteryOptimizations,
    ].request();
    return results.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<bool> ensureCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
