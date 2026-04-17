import 'package:flutter/material.dart';

import '../../domain/entities/alarm.dart';
import '../../domain/entities/weekday.dart';

class AlarmTile extends StatelessWidget {
  const AlarmTile({
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String get _timeLabel {
    final h = alarm.hour.toString().padLeft(2, '0');
    final m = alarm.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _daysLabel {
    if (alarm.repeatDays.isEmpty) return 'One-time';
    if (alarm.repeatDays.length == 7) return 'Every day';
    final sorted = alarm.repeatDays.toList()
      ..sort((a, b) => a.isoValue.compareTo(b.isoValue));
    return sorted.map((w) => w.shortLabel).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('alarm-${alarm.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_timeLabel,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            )),
                    const SizedBox(height: 4),
                    Text('${alarm.label.isEmpty ? 'Alarm' : alarm.label} · $_daysLabel',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Switch(value: alarm.enabled, onChanged: onToggle),
            ]),
          ),
        ),
      ),
    );
  }
}
