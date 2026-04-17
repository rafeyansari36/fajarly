import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/alarm.dart';
import '../../domain/entities/difficulty.dart';
import '../../domain/entities/expected_code.dart';
import '../../domain/entities/weekday.dart';
import '../providers/alarm_providers.dart';

class AddEditAlarmScreen extends ConsumerStatefulWidget {
  const AddEditAlarmScreen({this.alarmId, super.key});
  final int? alarmId;

  @override
  ConsumerState<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends ConsumerState<AddEditAlarmScreen> {
  late TimeOfDay _time;
  late TextEditingController _labelCtrl;
  Set<Weekday> _days = {};
  Difficulty _difficulty = Difficulty.one;
  bool _snooze = false;
  bool _enabled = true;
  ExpectedCode? _code;
  bool _loaded = false;

  bool get _isEdit => widget.alarmId != null;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _time = TimeOfDay(hour: now.hour, minute: now.minute);
    _labelCtrl = TextEditingController(text: 'Wake up');
    if (!_isEdit) {
      _loaded = true;
    } else {
      _hydrate();
    }
  }

  Future<void> _hydrate() async {
    final alarm = await ref.read(alarmRepositoryProvider).getById(widget.alarmId!);
    if (alarm == null || !mounted) return;
    setState(() {
      _time = TimeOfDay(hour: alarm.hour, minute: alarm.minute);
      _labelCtrl.text = alarm.label;
      _days = alarm.repeatDays;
      _difficulty = alarm.difficulty;
      _snooze = alarm.snoozeEnabled;
      _enabled = alarm.enabled;
      _code = alarm.expectedCode;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCode() async {
    final result = await context.push<ExpectedCode>('/scanner/setup');
    if (result != null) setState(() => _code = result);
  }

  Future<void> _generateCode() async {
    final result = await context.push<ExpectedCode>('/qr/generate?pickable=true');
    if (result != null) setState(() => _code = result);
  }

  Future<void> _save() async {
    if (_code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan an unlock code first')),
      );
      return;
    }
    final repo = ref.read(alarmRepositoryProvider);
    final id = widget.alarmId ?? repo.nextId();
    final alarm = Alarm(
      id: id,
      hour: _time.hour,
      minute: _time.minute,
      label: _labelCtrl.text.trim(),
      repeatDays: _days,
      expectedCode: _code!,
      difficulty: _difficulty,
      snoozeEnabled: _snooze,
      enabled: _enabled,
      createdAt: DateTime.now(),
    );
    await ref.read(scheduleAlarmProvider).call(alarm);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit alarm' : 'New alarm')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _TimePicker(
            time: _time,
            onChanged: (t) => setState(() => _time = t),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('Repeat'),
          const SizedBox(height: 8),
          _WeekdayPicker(
            selected: _days,
            onChanged: (next) => setState(() => _days = next),
          ),
          const SizedBox(height: 20),
          _SectionTitle('Unlock code'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text(
                _code == null ? 'Tap to scan a QR or barcode' : _code!.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _code == null
                    ? 'Use any product barcode or printed QR'
                    : 'Format: ${_code!.formatName}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCode,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _generateCode,
              icon: const Icon(Icons.qr_code_2, size: 18),
              label: const Text('Generate QR or barcode instead'),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('Difficulty'),
          const SizedBox(height: 8),
          SegmentedButton<Difficulty>(
            segments: Difficulty.values
                .map((d) => ButtonSegment(value: d, label: Text(d.label)))
                .toList(),
            selected: {_difficulty},
            onSelectionChanged: (s) => setState(() => _difficulty = s.first),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Snooze enabled'),
            subtitle: const Text('Penalty: scan twice after snooze'),
            value: _snooze,
            onChanged: (v) => setState(() => _snooze = v),
          ),
          SwitchListTile(
            title: const Text('Enabled'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({required this.time, required this.onChanged});
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: DateTime(2024, 1, 1, time.hour, time.minute),
        use24hFormat: true,
        onDateTimeChanged: (dt) => onChanged(TimeOfDay(hour: dt.hour, minute: dt.minute)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});
  final Set<Weekday> selected;
  final ValueChanged<Set<Weekday>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Weekday.values.map((w) {
        final on = selected.contains(w);
        return FilterChip(
          label: Text(w.shortLabel),
          selected: on,
          onSelected: (v) {
            final next = Set<Weekday>.from(selected);
            if (v) {
              next.add(w);
            } else {
              next.remove(w);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
