import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/streak_record.dart';
import '../providers/streak_providers.dart';

class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(streakStatsProvider);
    final recordsAsync = ref.watch(streakRecordsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Streaks')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            Expanded(
              child: _StatTile(
                label: 'Current',
                value: '${stats.currentStreak}',
                suffix: 'days',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Best',
                value: '${stats.bestStreak}',
                suffix: 'days',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Total',
                value: '${stats.totalWakeUps}',
                suffix: 'wakes',
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text('Last 30 days',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _Heatmap(days: stats.last30Days),
          const SizedBox(height: 28),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          recordsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (records) {
              if (records.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No wake-ups recorded yet. Your first scan will start the streak.'),
                );
              }
              final reversed = records.reversed.toList();
              return Column(
                children: [
                  for (final r in reversed) _HistoryRow(record: r),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.suffix});
  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
            Text(suffix, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.days});
  final List<bool> days;

  @override
  Widget build(BuildContext context) {
    if (days.length != 30) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 30,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final done = days[i];
        return Container(
          decoration: BoxDecoration(
            color: done ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});
  final StreakRecord record;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMMEEEEd();
    final fastest = record.fastestScanSeconds;
    final fastestLabel = fastest < 60
        ? '${fastest}s to scan'
        : '${(fastest / 60).toStringAsFixed(1)} min to scan';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.check,
            color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: Text(df.format(record.date)),
      subtitle: Text(
        '${record.wakeCount} wake-up${record.wakeCount == 1 ? '' : 's'} · $fastestLabel',
      ),
    );
  }
}
