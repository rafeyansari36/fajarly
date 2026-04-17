import '../entities/alarm.dart';

abstract interface class AlarmRepository {
  Future<void> upsert(Alarm alarm);
  Future<void> delete(int id);
  Future<Alarm?> getById(int id);
  Future<List<Alarm>> listAll();
  Stream<List<Alarm>> watchAll();
  int nextId();
}
