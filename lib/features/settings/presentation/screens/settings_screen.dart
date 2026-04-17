import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/utils/oem_autostart.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../data/settings_prefs.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(settingsPrefsProvider);
    ref.watch(settingsTickProvider);
    final theme = prefs.themeMode;
    final snooze = prefs.snoozeMinutes;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(theme.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref, current: theme),
          ),
          const Divider(),
          const _SectionHeader('Alarms'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Snooze duration',
                    style: Theme.of(context).textTheme.bodyLarge),
                Row(children: [
                  Expanded(
                    child: Slider(
                      min: SettingsPrefs.minSnoozeMinutes.toDouble(),
                      max: SettingsPrefs.maxSnoozeMinutes.toDouble(),
                      divisions:
                          SettingsPrefs.maxSnoozeMinutes - SettingsPrefs.minSnoozeMinutes,
                      value: snooze.toDouble(),
                      label: '$snooze min',
                      onChanged: (v) => prefs.setSnoozeMinutes(v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text('$snooze min',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ]),
                Text(
                  'Each snooze also adds one scan to the unlock requirement.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const _SectionHeader('Reliability'),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Alarm diagnostics'),
            subtitle:
                const Text('Verify every permission that lets alarms fire on the lock screen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/diagnostics'),
          ),
          ListTile(
            leading: const Icon(Icons.battery_charging_full),
            title: const Text('Autostart (manufacturer)'),
            subtitle: const Text('Open the OEM-specific autostart screen'),
            onTap: () async {
              final oem = ref.read(oemAutostartProvider);
              final manufacturer = await oem.detectManufacturer();
              if (manufacturer != null) {
                await oem.openAutostartSettings(manufacturer);
              }
            },
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Fajarly'),
            subtitle: Text('Version 0.1.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref, {
    required AppThemeMode current,
  }) async {
    final prefs = ref.read(settingsPrefsProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in AppThemeMode.values)
              RadioListTile<AppThemeMode>(
                value: m,
                groupValue: current,
                title: Text(m.label),
                onChanged: (v) async {
                  if (v == null) return;
                  await prefs.setThemeMode(v);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
