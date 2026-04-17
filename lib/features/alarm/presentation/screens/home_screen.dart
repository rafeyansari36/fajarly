import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/permission_helper.dart';
import '../../../streaks/presentation/widgets/streak_summary_card.dart';
import '../providers/alarm_providers.dart';
import '../widgets/alarm_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const PermissionHelper().ensureAlarmPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alarmsAsync = ref.watch(alarmsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fajarly'),
        titleTextStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Generate QR',
            onPressed: () => context.push('/qr/generate'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: alarmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alarms) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const StreakSummaryCard(),
              const SizedBox(height: 16),
              if (alarms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: _EmptyState(),
                )
              else
                for (final a in alarms) ...[
                  AlarmTile(
                    alarm: a,
                    onTap: () => context.push('/alarm/edit/${a.id}'),
                    onToggle: (enabled) async {
                      final updated = a.copyWith(enabled: enabled);
                      await ref.read(scheduleAlarmProvider).call(updated);
                    },
                    onDelete: () async {
                      await ref.read(deleteAlarmProvider).call(a.id);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/alarm/new'),
        icon: const Icon(Icons.add),
        label: const Text('New alarm'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm, size: 64),
            const SizedBox(height: 16),
            Text('No alarms yet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Create your first alarm and pick any barcode or QR as your unlock key.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
