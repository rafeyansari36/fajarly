import '../entities/alarm.dart';
import '../repositories/alarm_repository.dart';
import '../services/alarm_scheduler.dart';

class ScheduleAlarm {
  const ScheduleAlarm(this._repo, this._scheduler);
  final AlarmRepository _repo;
  final AlarmScheduler _scheduler;

  Future<void> call(Alarm alarm) async {
    await _repo.upsert(alarm);
    if (alarm.enabled) {
      await _scheduler.schedule(alarm);
    } else {
      await _scheduler.cancel(alarm.id);
    }
  }
}
