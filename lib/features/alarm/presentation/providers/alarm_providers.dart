import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../data/models/alarm_model.dart';
import '../../data/repositories/alarm_repository_impl.dart';
import '../../data/services/alarm_scheduler_impl.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../../domain/services/alarm_scheduler.dart';
import '../../domain/usecases/delete_alarm.dart';
import '../../domain/usecases/schedule_alarm.dart';

final alarmBoxProvider = Provider<Box<AlarmModel>>((_) {
  return Hive.box<AlarmModel>('alarms');
});

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepositoryImpl(ref.watch(alarmBoxProvider));
});

final alarmSchedulerProvider = Provider<AlarmScheduler>((_) {
  return const AlarmSchedulerImpl();
});

final scheduleAlarmProvider = Provider<ScheduleAlarm>((ref) {
  return ScheduleAlarm(
    ref.watch(alarmRepositoryProvider),
    ref.watch(alarmSchedulerProvider),
  );
});

final deleteAlarmProvider = Provider<DeleteAlarm>((ref) {
  return DeleteAlarm(
    ref.watch(alarmRepositoryProvider),
    ref.watch(alarmSchedulerProvider),
  );
});

final alarmsStreamProvider = StreamProvider<List<Alarm>>((ref) {
  return ref.watch(alarmRepositoryProvider).watchAll();
});

final alarmByIdProvider = FutureProvider.family<Alarm?, int>((ref, id) {
  return ref.watch(alarmRepositoryProvider).getById(id);
});
