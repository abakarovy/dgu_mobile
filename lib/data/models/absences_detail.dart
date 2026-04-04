/// Строка семестра из `GET /api/1c/absences` (`semesters[]`).
class AbsenceSemesterRow {
  const AbsenceSemesterRow({
    required this.semester,
    this.year,
    this.totalAbsences,
    this.totalHours,
  });

  final String semester;
  final int? year;
  final int? totalAbsences;
  final double? totalHours;
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
