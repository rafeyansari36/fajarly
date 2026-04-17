import '../entities/streak_record.dart';

abstract interface class StreakRepository {
  Future<void> recordWakeUp({
    required int alarmId,
    required DateTime scannedAt,
    required int secondsToScan,
  });
  Future<List<StreakRecord>> listAll();
  Stream<List<StreakRecord>> watchAll();
}
