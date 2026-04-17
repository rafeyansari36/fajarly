import 'package:hive_ce/hive.dart';

import '../../domain/entities/alarm.dart';
import '../../domain/entities/difficulty.dart';
import '../../domain/entities/expected_code.dart';
import '../../domain/entities/weekday.dart';

class AlarmModel {
  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.repeatDays,
    required this.unlockCodeValue,
    required this.unlockCodeFormat,
    required this.difficultyIdx,
    required this.snoozeEnabled,
    required this.enabled,
    required this.createdAtMs,
  });

  final int id;
  final int hour;
  final int minute;
  final String label;
  final List<int> repeatDays;
  final String unlockCodeValue;
  final String unlockCodeFormat;
  final int difficultyIdx;
  final bool snoozeEnabled;
  final bool enabled;
  final int createdAtMs;

  Alarm toEntity() => Alarm(
        id: id,
        hour: hour,
        minute: minute,
        label: label,
        repeatDays: repeatDays.map(Weekday.fromIso).toSet(),
        expectedCode: ExpectedCode(value: unlockCodeValue, formatName: unlockCodeFormat),
        difficulty: Difficulty.values[difficultyIdx],
        snoozeEnabled: snoozeEnabled,
        enabled: enabled,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      );

  static AlarmModel fromEntity(Alarm a) => AlarmModel(
        id: a.id,
        hour: a.hour,
        minute: a.minute,
        label: a.label,
        repeatDays: a.repeatDays.map((w) => w.isoValue).toList(),
        unlockCodeValue: a.expectedCode.value,
        unlockCodeFormat: a.expectedCode.formatName,
        difficultyIdx: a.difficulty.index,
        snoozeEnabled: a.snoozeEnabled,
        enabled: a.enabled,
        createdAtMs: a.createdAt.millisecondsSinceEpoch,
      );
}

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 1;

  @override
  AlarmModel read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as int,
      hour: fields[1] as int,
      minute: fields[2] as int,
      label: fields[3] as String,
      repeatDays: (fields[4] as List).cast<int>(),
      unlockCodeValue: fields[5] as String,
      unlockCodeFormat: fields[6] as String,
      difficultyIdx: fields[7] as int,
      snoozeEnabled: fields[8] as bool,
      enabled: fields[9] as bool,
      createdAtMs: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.hour)
      ..writeByte(2)..write(obj.minute)
      ..writeByte(3)..write(obj.label)
      ..writeByte(4)..write(obj.repeatDays)
      ..writeByte(5)..write(obj.unlockCodeValue)
      ..writeByte(6)..write(obj.unlockCodeFormat)
      ..writeByte(7)..write(obj.difficultyIdx)
      ..writeByte(8)..write(obj.snoozeEnabled)
      ..writeByte(9)..write(obj.enabled)
      ..writeByte(10)..write(obj.createdAtMs);
  }
}
