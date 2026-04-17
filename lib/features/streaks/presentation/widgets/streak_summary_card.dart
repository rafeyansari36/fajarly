import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/streak_providers.dart';

class StreakSummaryCard extends ConsumerWidget {
  const StreakSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(streakStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: () => context.push('/streaks'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.currentStreak}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                Text(
                  stats.currentStreak == 1 ? 'day streak' : 'day streak',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                ),
              ],
            ),
            const Spacer(),
            _DayStrip(days: stats.last30Days.sublist(
              stats.last30Days.length >= 14 ? stats.last30Days.length - 14 : 0,
            )),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
          ]),
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.days});
  final List<bool> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: days.map((done) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 8,
            height: 24,
            decoration: BoxDecoration(
              color: done
                  ? scheme.onPrimaryContainer
                  : scheme.onPrimaryContainer.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }
}
