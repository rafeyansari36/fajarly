import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../../domain/entities/alarm.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../models/alarm_model.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  AlarmRepositoryImpl(this._box);
  final Box<AlarmModel> _box;

  @override
  Future<void> upsert(Alarm alarm) =>
      _box.put(alarm.id, AlarmModel.fromEntity(alarm));

  @override
  Future<void> delete(int id) => _box.delete(id);

  @override
  Future<Alarm?> getById(int id) async => _box.get(id)?.toEntity();

  @override
  Future<List<Alarm>> listAll() async =>
      _box.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) {
          final aMin = a.hour * 60 + a.minute;
          final bMin = b.hour * 60 + b.minute;
          return aMin.compareTo(bMin);
        });

  @override
  Stream<List<Alarm>> watchAll() async* {
    yield await listAll();
    yield* _box.watch().asyncMap((_) => listAll());
  }

  @override
  int nextId() {
    if (_box.isEmpty) return 1;
    final maxId = _box.values.map((m) => m.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}
