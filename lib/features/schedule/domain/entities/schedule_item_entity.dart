/// Элемент расписания (пара/занятие).
class ScheduleItemEntity {
  const ScheduleItemEntity({
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacherName,
  });

  final String subjectName;
  final DateTime startTime;
  final DateTime endTime;
  final String? room;
  final String? teacherName;
}
