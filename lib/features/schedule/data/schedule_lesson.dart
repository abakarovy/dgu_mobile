/// Элемент расписания для отображения (одна пара).
class ScheduleLesson {
  const ScheduleLesson({
    this.weekdayIndex,
    this.lessonDate,
    this.pairNumber,
    required this.subject,
    required this.time,
    required this.teacher,
    required this.auditorium,
  });

  /// 0=ПН … 6=ВС (если бэк отдал day_short), иначе null.
  final int? weekdayIndex;

  /// Календарная дата занятия (из поля `date` бэка, dd.MM.yyyy).
  final DateTime? lessonDate;

  /// Номер пары с бэка (`pair_number`), для сортировки и группировки.
  final int? pairNumber;

  final String subject;
  final String time;
  final String teacher;
  final String auditorium;

  /// Для кэша: `lesson_date` — только дата `yyyy-MM-dd`.
  Map<String, dynamic> toJsonMap() => {
        'weekday_index': weekdayIndex,
        'lesson_date': lessonDate == null
            ? null
            : '${lessonDate!.year.toString().padLeft(4, '0')}-'
                '${lessonDate!.month.toString().padLeft(2, '0')}-'
                '${lessonDate!.day.toString().padLeft(2, '0')}',
        'pair_number': pairNumber,
        'subject': subject,
        'time': time,
        'teacher': teacher,
        'auditorium': auditorium,
      };

  factory ScheduleLesson.fromJsonMap(Map<String, dynamic> j) {
    DateTime? lessonDate;
    final raw = j['lesson_date'];
    if (raw is String && raw.isNotEmpty) {
      lessonDate = DateTime.tryParse(raw);
      if (lessonDate != null) {
        lessonDate = DateTime(lessonDate.year, lessonDate.month, lessonDate.day);
      }
    }
    int? pairNo;
    final pn = j['pair_number'];
    if (pn is int) {
      pairNo = pn;
    } else if (pn != null) {
      pairNo = int.tryParse('$pn');
    }
    return ScheduleLesson(
      weekdayIndex: j['weekday_index'] is int ? (j['weekday_index'] as int) : null,
      lessonDate: lessonDate,
      pairNumber: pairNo,
      subject: (j['subject'] as String?) ?? '',
      time: (j['time'] as String?) ?? '',
      teacher: (j['teacher'] as String?) ?? '',
      auditorium: (j['auditorium'] as String?) ?? '',
    );
  }
}

