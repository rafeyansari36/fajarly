import '../entities/streak_record.dart';
import '../entities/streak_stats.dart';

class ComputeStats {
  const ComputeStats();

  StreakStats call(List<StreakRecord> records, {DateTime? now}) {
    if (records.isEmpty) return StreakStats.empty;

    final today = StreakRecord.midnightOf(now ?? DateTime.now());
    final dates = records
        .map((r) => StreakRecord.midnightOf(r.date))
        .toSet()
        .toList()
      ..sort();

    // Current streak: walk backwards from today. If today is missing, try
    // yesterday so the user doesn't see their streak reset until the full
    // calendar day has elapsed without a wake-up.
    var current = 0;
    var cursor = today;
    final dateSet = dates.toSet();
    if (!dateSet.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (dateSet.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Best streak: single linear pass over sorted unique dates.
    var best = 1;
    var run = 1;
    for (var i = 1; i < dates.length; i++) {
      final prev = dates[i - 1];
      final cur = dates[i];
      if (cur.difference(prev).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    // If there's only one record total we still want best = 1.
    if (dates.length == 1) best = 1;

    final totalWakeUps = records.fold<int>(0, (sum, r) => sum + r.wakeCount);

    final last30Days = List<bool>.generate(30, (i) {
      final day = today.subtract(Duration(days: 29 - i));
      return dateSet.contains(day);
    });

    return StreakStats(
      currentStreak: current,
      bestStreak: best,
      totalWakeUps: totalWakeUps,
      last30Days: last30Days,
    );
  }
}
