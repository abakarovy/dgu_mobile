/// Оценка по дисциплине.
class GradeEntity {
  const GradeEntity({
    required this.subjectName,
    required this.grade,
    this.date,
    this.teacherName,
  });

  final String subjectName;
  final String grade;
  final DateTime? date;
  final String? teacherName;
}
