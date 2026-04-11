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
      final s = raw.trim();
      final ymd = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
      if (ymd != null) {
        final y = int.tryParse(ymd.group(1)!);
        final mo = int.tryParse(ymd.group(2)!);
        final d = int.tryParse(ymd.group(3)!);
        if (y != null && mo != null && d != null) {
          lessonDate = DateTime(y, mo, d);
        }
      }
      lessonDate ??= DateTime.tryParse(s);
      if (lessonDate != null) {
        lessonDate = DateTime(lessonDate.year, lessonDate.month, lessonDate.day);
      }
    }
    if (lessonDate == null) {
      final ds = j['date'];
      if (ds is String && ds.isNotEmpty) {
        final dot = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');
        final m = dot.firstMatch(ds.trim());
        if (m != null) {
          final d = int.tryParse(m.group(1)!);
          final mo = int.tryParse(m.group(2)!);
          final y = int.tryParse(m.group(3)!);
          if (d != null && mo != null && y != null) {
            lessonDate = DateTime(y, mo, d);
          }
        }
      }
    }
    int? pairNo;
    final pn = j['pair_number'];
    if (pn is int) {
      pairNo = pn;
    } else if (pn != null) {
      pairNo = int.tryParse('$pn');
    }
    int? widx = j['weekday_index'] is int ? (j['weekday_index'] as int) : null;
    if (widx == null && lessonDate != null) {
      widx = lessonDate.weekday - 1;
    }
    return ScheduleLesson(
      weekdayIndex: widx,
      lessonDate: lessonDate,
      pairNumber: pairNo,
      subject: (j['subject'] as String?) ?? '',
      time: (j['time'] as String?) ?? '',
      teacher: (j['teacher'] as String?) ?? '',
      auditorium: (j['auditorium'] as String?) ?? '',
    );
  }
}

