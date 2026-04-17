enum Weekday {
  monday(1, 'Mon'),
  tuesday(2, 'Tue'),
  wednesday(3, 'Wed'),
  thursday(4, 'Thu'),
  friday(5, 'Fri'),
  saturday(6, 'Sat'),
  sunday(7, 'Sun');

  const Weekday(this.isoValue, this.shortLabel);
  final int isoValue;
  final String shortLabel;

  static Weekday fromIso(int iso) =>
      Weekday.values.firstWhere((w) => w.isoValue == iso);
}
