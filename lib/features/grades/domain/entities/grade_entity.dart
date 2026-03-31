/// Оценка по дисциплине.
class GradeEntity {
  const GradeEntity({
    required this.subjectName,
    required this.grade,
    this.gradeType,
    this.date,
    this.teacherName,
    this.semester,
  });

  final String subjectName;
  final String grade;
  final String? gradeType;
  final DateTime? date;
  final String? teacherName;
  /// Семестр в формате бэка, напр. `1 сем 2025-2026`.
  final String? semester;
}
