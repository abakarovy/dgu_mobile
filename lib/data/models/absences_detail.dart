/// Строка семестра из `GET /api/1c/absences` (`semesters[]`).
class AbsenceSemesterRow {
  const AbsenceSemesterRow({
    required this.semester,
    this.year,
    this.totalAbsences,
    this.totalHours,
    this.excusedAbsences,
    this.unexcusedAbsences,
  });

  final String semester;
  final int? year;
  final int? totalAbsences;
  final double? totalHours;
  /// `data.excused_absences` из `GET /api/1c/absences`.
  final int? excusedAbsences;
  /// `data.unexcused_absences` из `GET /api/1c/absences`.
  final int? unexcusedAbsences;
}

/// Ответ пропусков: семестры и опционально строки «журнала».
class AbsencesDetail {
  const AbsencesDetail({
    required this.semesters,
    this.items = const <Map<String, dynamic>>[],
  });

  final List<AbsenceSemesterRow> semesters;
  final List<Map<String, dynamic>> items;
}
