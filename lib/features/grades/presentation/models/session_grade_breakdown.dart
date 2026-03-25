/// Результаты сессии по дисциплине: аттестации и итоговые формы (как в ведомости, не таблица).
class SessionGradeBreakdown {
  const SessionGradeBreakdown({
    this.att1,
    this.att2,
    this.dfk,
    this.kurs,
    this.zach,
    this.ekz,
  });

  /// Подписи как в учебной части: «атт», «отл», «—» при отсутствии.
  final String? att1;
  final String? att2;
  final String? dfk;
  final String? kurs;
  final String? zach;
  final String? ekz;
}
