import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../data/models/streak_record_model.dart';
import '../../data/repositories/streak_repository_impl.dart';
import '../../domain/entities/streak_record.dart';
import '../../domain/entities/streak_stats.dart';
import '../../domain/repositories/streak_repository.dart';
import '../../domain/usecases/compute_stats.dart';

final streakBoxProvider = Provider<Box<StreakRecordModel>>((_) {
  return Hive.box<StreakRecordModel>('streaks');
});

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepositoryImpl(ref.watch(streakBoxProvider));
});

final computeStatsProvider = Provider<ComputeStats>((_) => const ComputeStats());

final streakRecordsStreamProvider = StreamProvider<List<StreakRecord>>((ref) {
  return ref.watch(streakRepositoryProvider).watchAll();
});

final streakStatsProvider = Provider<StreakStats>((ref) {
  final records = ref.watch(streakRecordsStreamProvider).valueOrNull ?? const [];
  return ref.watch(computeStatsProvider).call(records);
});
