import '../entities/alarm.dart';

abstract interface class AlarmScheduler {
  Future<void> schedule(Alarm alarm);
  Future<void> cancel(int id);
  Future<void> stopRinging(int id);

  /// Reschedules [alarm] for a one-shot fire at [fireAt]. The original
  /// recurring schedule (if any) is overwritten for this alarm id and must
  /// be restored by the caller after the snoozed alarm is dismissed.
  Future<void> scheduleSnooze(Alarm alarm, DateTime fireAt);
}
