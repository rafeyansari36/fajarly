class StreakRecord {
  const StreakRecord({
    required this.date,
    required this.lastAlarmId,
    required this.wakeCount,
    required this.fastestScanSeconds,
  });

  /// Local midnight for the day the user woke up.
  final DateTime date;
  final int lastAlarmId;
  final int wakeCount;
  final int fastestScanSeconds;

  String get dateKey => keyFor(date);

  static String keyFor(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime midnightOf(DateTime d) => DateTime(d.year, d.month, d.day);
}
