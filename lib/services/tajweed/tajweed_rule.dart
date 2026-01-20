enum TajweedRule {
  LAFZATULLAH(1),
  izhar(2),
  ikhfaa(3),
  idghamWithGhunna(4),
  iqlab(5),
  qalqala(6),
  idghamWithoutGhunna(7),
  ghunna(8),
  prolonging(9),
  alefTafreeq(10),
  hamzatulWasli(11),
  lamShamsiyyah(12),
  silent(13),
  none(100);

  const TajweedRule(this.priority);

  final int priority;
}
