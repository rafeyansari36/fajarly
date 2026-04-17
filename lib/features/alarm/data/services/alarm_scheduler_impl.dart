import 'package:alarm/alarm.dart' as pkg;

import '../../domain/entities/alarm.dart';
import '../../domain/services/alarm_scheduler.dart';

class AlarmSchedulerImpl implements AlarmScheduler {
  const AlarmSchedulerImpl();

  @override
  Future<void> schedule(Alarm alarm) async {
    final nextFire = _nextFireDate(alarm, DateTime.now());
    final settings = pkg.AlarmSettings(
      id: alarm.id,
      dateTime: nextFire,
      assetAudioPath: 'assets/audio/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: pkg.VolumeSettings.fade(
        volume: 0.9,
        fadeDuration: const Duration(seconds: 5),
      ),
      notificationSettings: pkg.NotificationSettings(
        title: alarm.label.isEmpty ? 'Fajarly' : alarm.label,
        body: 'Scan your unlock code to stop the alarm',
      ),
    );
    await pkg.Alarm.set(alarmSettings: settings);
  }

  @override
  Future<void> cancel(int id) => pkg.Alarm.stop(id);

  @override
  Future<void> stopRinging(int id) => pkg.Alarm.stop(id);

  @override
  Future<void> scheduleSnooze(Alarm alarm, DateTime fireAt) async {
    final settings = pkg.AlarmSettings(
      id: alarm.id,
      dateTime: fireAt,
      assetAudioPath: 'assets/audio/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: pkg.VolumeSettings.fade(
        volume: 0.9,
        fadeDuration: const Duration(seconds: 3),
      ),
      notificationSettings: pkg.NotificationSettings(
        title: alarm.label.isEmpty ? 'Fajarly (snoozed)' : '${alarm.label} (snoozed)',
        body: 'Scan your unlock code to stop the alarm',
      ),
    );
    await pkg.Alarm.set(alarmSettings: settings);
  }

  DateTime _nextFireDate(Alarm alarm, DateTime now) {
    final today = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    if (alarm.isOneShot) {
      return today.isAfter(now) ? today : today.add(const Duration(days: 1));
    }
    for (var i = 0; i < 8; i++) {
      final candidate = today.add(Duration(days: i));
      final iso = candidate.weekday;
      final matches = alarm.repeatDays.any((w) => w.isoValue == iso);
      if (matches && candidate.isAfter(now)) return candidate;
    }
    return today.add(const Duration(days: 1));
  }
}

/// Recurrence rescheduler — call after an alarm fires to queue the next one.
/// Exposed for both the isolate callback and the ringing screen.
DateTime nextFireFor(Alarm alarm, DateTime from) {
  final base = DateTime(from.year, from.month, from.day, alarm.hour, alarm.minute);
  if (alarm.isOneShot) {
    return base.isAfter(from) ? base : base.add(const Duration(days: 1));
  }
  for (var i = 1; i <= 8; i++) {
    final candidate = base.add(Duration(days: i));
    if (alarm.repeatDays.any((w) => w.isoValue == candidate.weekday)) {
      return candidate;
    }
  }
  return base.add(const Duration(days: 1));
}
