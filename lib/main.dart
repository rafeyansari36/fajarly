import 'package:alarm/alarm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'features/alarm/data/models/alarm_model.dart';
import 'features/streaks/data/models/streak_record_model.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash on screen until init finishes — no flash of
  // unstyled content between the Android launch screen and our first frame.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await Hive.initFlutter();
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(StreakRecordModelAdapter());
  await Hive.openBox<AlarmModel>('alarms');
  await Hive.openBox<StreakRecordModel>('streaks');
  await Hive.openBox<dynamic>('prefs');

  await Alarm.init();

  runApp(const ProviderScope(child: FajarlyApp()));
  FlutterNativeSplash.remove();
}
