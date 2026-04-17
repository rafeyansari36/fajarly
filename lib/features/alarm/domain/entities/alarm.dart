import 'difficulty.dart';
import 'expected_code.dart';
import 'weekday.dart';

class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.repeatDays,
    required this.expectedCode,
    required this.difficulty,
    required this.snoozeEnabled,
    required this.enabled,
    required this.createdAt,
  });

  final int id;
  final int hour;
  final int minute;
  final String label;
  final Set<Weekday> repeatDays;
  final ExpectedCode expectedCode;
  final Difficulty difficulty;
  final bool snoozeEnabled;
  final bool enabled;
  final DateTime createdAt;

  bool get isOneShot => repeatDays.isEmpty;

  Alarm copyWith({
    int? hour,
    int? minute,
    String? label,
    Set<Weekday>? repeatDays,
    ExpectedCode? expectedCode,
    Difficulty? difficulty,
    bool? snoozeEnabled,
    bool? enabled,
  }) {
    return Alarm(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      expectedCode: expectedCode ?? this.expectedCode,
      difficulty: difficulty ?? this.difficulty,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
    );
  }
}
