enum Difficulty {
  one('Scan 1 code'),
  two('Scan 2 different codes'),
  escalating('Escalating (snooze doubles count)');

  const Difficulty(this.label);
  final String label;
}
