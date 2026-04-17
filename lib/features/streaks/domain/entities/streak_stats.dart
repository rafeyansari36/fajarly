class StreakStats {
  const StreakStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalWakeUps,
    required this.last30Days,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalWakeUps;

  /// Newest-last list of 30 booleans (yesterday-29 … today) — true if the
  /// user recorded a wake-up on that day. Used for the strip chart.
  final List<bool> last30Days;

  static const empty = StreakStats(
    currentStreak: 0,
    bestStreak: 0,
    totalWakeUps: 0,
    last30Days: <bool>[],
  );
}
