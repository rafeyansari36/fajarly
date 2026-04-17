import 'package:hive_ce/hive.dart';

class OnboardingPrefs {
  OnboardingPrefs(this._box);
  final Box<dynamic> _box;

  static const _keyCompleted = 'onboarding_completed';

  bool get isCompleted => _box.get(_keyCompleted, defaultValue: false) as bool;

  Future<void> markCompleted() => _box.put(_keyCompleted, true);

  /// Stream of the completion flag so GoRouter can redirect reactively.
  Stream<bool> watch() async* {
    yield isCompleted;
    yield* _box.watch(key: _keyCompleted).map((_) => isCompleted);
  }
}
