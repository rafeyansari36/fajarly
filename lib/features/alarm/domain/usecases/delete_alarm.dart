import '../repositories/alarm_repository.dart';
import '../services/alarm_scheduler.dart';

class DeleteAlarm {
  const DeleteAlarm(this._repo, this._scheduler);
  final AlarmRepository _repo;
  final AlarmScheduler _scheduler;

  Future<void> call(int id) async {
    await _scheduler.cancel(id);
    await _repo.delete(id);
  }
}
