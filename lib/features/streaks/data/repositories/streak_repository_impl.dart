import 'dart:async';
import 'dart:math' as math;

import 'package:hive_ce/hive.dart';

import '../../domain/entities/streak_record.dart';
import '../../domain/repositories/streak_repository.dart';
import '../models/streak_record_model.dart';

class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl(this._box);
  final Box<StreakRecordModel> _box;

  @override
  Future<void> recordWakeUp({
    required int alarmId,
    required DateTime scannedAt,
    required int secondsToScan,
  }) async {
    final day = StreakRecord.midnightOf(scannedAt);
    final key = StreakRecord.keyFor(day);
    final existing = _box.get(key);
    if (existing == null) {
      await _box.put(
        key,
        StreakRecordModel(
          dateMs: day.millisecondsSinceEpoch,
          lastAlarmId: alarmId,
          wakeCount: 1,
          fastestScanSeconds: secondsToScan,
        ),
      );
    } else {
      await _box.put(
        key,
        StreakRecordModel(
          dateMs: existing.dateMs,
          lastAlarmId: alarmId,
          wakeCount: existing.wakeCount + 1,
          fastestScanSeconds:
              math.min(existing.fastestScanSeconds, secondsToScan),
        ),
      );
    }
  }

  @override
  Future<List<StreakRecord>> listAll() async {
    return _box.values.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Stream<List<StreakRecord>> watchAll() async* {
    yield await listAll();
    yield* _box.watch().asyncMap((_) => listAll());
  }
}
