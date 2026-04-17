import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Opens the manufacturer-specific screen where the user grants autostart
/// / battery-unrestricted permissions. There is no public Android API for
/// this — each OEM ships a proprietary activity and they do change over
/// time. If an entry stops working on a new ROM, ship an update with the
/// new component name. Returns `false` if we don't have a mapping or the
/// intent couldn't be launched.
class OemAutostart {
  const OemAutostart();

  static const _map = <String, List<_Component>>{
    'xiaomi': [
      _Component('com.miui.securitycenter',
          'com.miui.permcenter.autostart.AutoStartManagementActivity'),
    ],
    'redmi': [
      _Component('com.miui.securitycenter',
          'com.miui.permcenter.autostart.AutoStartManagementActivity'),
    ],
    'poco': [
      _Component('com.miui.securitycenter',
          'com.miui.permcenter.autostart.AutoStartManagementActivity'),
    ],
    'oppo': [
      _Component('com.coloros.safecenter',
          'com.coloros.safecenter.permission.startup.StartupAppListActivity'),
      _Component('com.oppo.safe',
          'com.oppo.safe.permission.startup.StartupAppListActivity'),
    ],
    'realme': [
      _Component('com.coloros.safecenter',
          'com.coloros.safecenter.permission.startup.StartupAppListActivity'),
    ],
    'vivo': [
      _Component('com.vivo.permissionmanager',
          'com.vivo.permissionmanager.activity.BgStartUpManagerActivity'),
    ],
    'huawei': [
      _Component('com.huawei.systemmanager',
          'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity'),
    ],
    'honor': [
      _Component('com.huawei.systemmanager',
          'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity'),
    ],
    'samsung': [
      _Component('com.samsung.android.lool',
          'com.samsung.android.sm.ui.battery.BatteryActivity'),
    ],
    'asus': [
      _Component('com.asus.mobilemanager',
          'com.asus.mobilemanager.powersaver.PowerSaverSettings'),
    ],
  };

  Future<String?> detectManufacturer() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.manufacturer.toLowerCase();
  }

  bool hasMappingFor(String? manufacturer) =>
      manufacturer != null && _map.containsKey(manufacturer);

  Future<bool> openAutostartSettings(String manufacturer) async {
    final candidates = _map[manufacturer];
    if (candidates == null) return false;
    for (final c in candidates) {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName: '${c.pkg}/${c.cls}',
      );
      try {
        await intent.launch();
        return true;
      } catch (_) {
        // Try the next candidate — package may not exist on this ROM build.
        continue;
      }
    }
    return false;
  }
}

class _Component {
  const _Component(this.pkg, this.cls);
  final String pkg;
  final String cls;
}
