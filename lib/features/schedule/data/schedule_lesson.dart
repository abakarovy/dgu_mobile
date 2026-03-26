/// Элемент расписания для отображения (одна пара).
class ScheduleLesson {
  const ScheduleLesson({
    this.weekdayIndex,
    required this.subject,
    required this.time,
    required this.teacher,
    required this.auditorium,
  });

  /// 0=ПН … 6=ВС (если бэк отдал day_short), иначе null.
  final int? weekdayIndex;
  final String subject;
  final String time;
  final String teacher;
  final String auditorium;
}

