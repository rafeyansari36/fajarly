import 'package:hive_ce/hive.dart';

import '../../domain/entities/streak_record.dart';

class StreakRecordModel {
  StreakRecordModel({
    required this.dateMs,
    required this.lastAlarmId,
    required this.wakeCount,
    required this.fastestScanSeconds,
  });

  final int dateMs;
  final int lastAlarmId;
  final int wakeCount;
  final int fastestScanSeconds;

  StreakRecord toEntity() => StreakRecord(
        date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        lastAlarmId: lastAlarmId,
        wakeCount: wakeCount,
        fastestScanSeconds: fastestScanSeconds,
      );

  static StreakRecordModel fromEntity(StreakRecord r) => StreakRecordModel(
        dateMs: StreakRecord.midnightOf(r.date).millisecondsSinceEpoch,
        lastAlarmId: r.lastAlarmId,
        wakeCount: r.wakeCount,
        fastestScanSeconds: r.fastestScanSeconds,
      );
}

class StreakRecordModelAdapter extends TypeAdapter<StreakRecordModel> {
  @override
  final int typeId = 2;

  @override
  StreakRecordModel read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldsCount; i++) reader.readByte(): reader.read(),
    };
    return StreakRecordModel(
      dateMs: fields[0] as int,
      lastAlarmId: fields[1] as int,
      wakeCount: fields[2] as int,
      fastestScanSeconds: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StreakRecordModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)..write(obj.dateMs)
      ..writeByte(1)..write(obj.lastAlarmId)
      ..writeByte(2)..write(obj.wakeCount)
      ..writeByte(3)..write(obj.fastestScanSeconds);
  }
}
