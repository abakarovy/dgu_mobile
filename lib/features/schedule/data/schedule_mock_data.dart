/// Элемент расписания для отображения (одна пара).
class ScheduleLesson {
  const ScheduleLesson({
    required this.subject,
    required this.time,
    required this.teacher,
    required this.auditorium,
  });

  final String subject;
  final String time;
  final String teacher;
  final String auditorium;
}

/// Расписание по дням недели (0 = ПН, 6 = ВС). Один источник данных для главной и экрана расписания.
List<ScheduleLesson> scheduleLessonsForDay(int dayIndex) {
  final days = <List<ScheduleLesson>>[
    [
      const ScheduleLesson(subject: 'Веб разработка', time: '8:30', teacher: 'Алиева А.М.', auditorium: 'каб. 201'),
      const ScheduleLesson(subject: 'Базы данных', time: '10:10', teacher: 'Иванов И.И.', auditorium: 'каб. 301'),
      const ScheduleLesson(subject: 'Математика', time: '12:00', teacher: 'Петрова П.П.', auditorium: 'каб. 102'),
    ],
    [
      const ScheduleLesson(subject: 'Программирование', time: '9:00', teacher: 'Сидоров С.С.', auditorium: 'каб. 205'),
      const ScheduleLesson(subject: 'Физкультура', time: '10:50', teacher: 'Козлов К.К.', auditorium: 'спортзал'),
      const ScheduleLesson(subject: 'Английский язык', time: '13:30', teacher: 'Новикова Н.Н.', auditorium: 'каб. 401'),
    ],
    [
      const ScheduleLesson(subject: 'Базы данных', time: '8:30', teacher: 'Иванов И.И.', auditorium: 'каб. 301'),
      const ScheduleLesson(subject: 'Веб разработка', time: '10:10', teacher: 'Алиева А.М.', auditorium: 'каб. 201'),
      const ScheduleLesson(subject: 'История', time: '12:00', teacher: 'Морозова М.М.', auditorium: 'каб. 105'),
    ],
    [
      const ScheduleLesson(subject: 'Математика', time: '9:00', teacher: 'Петрова П.П.', auditorium: 'каб. 102'),
      const ScheduleLesson(subject: 'Программирование', time: '11:00', teacher: 'Сидоров С.С.', auditorium: 'каб. 205'),
    ],
    [
      const ScheduleLesson(subject: 'Английский язык', time: '8:30', teacher: 'Новикова Н.Н.', auditorium: 'каб. 401'),
      const ScheduleLesson(subject: 'Физкультура', time: '10:10', teacher: 'Козлов К.К.', auditorium: 'спортзал'),
      const ScheduleLesson(subject: 'Веб разработка', time: '12:00', teacher: 'Алиева А.М.', auditorium: 'каб. 201'),
    ],
    [
      const ScheduleLesson(subject: 'Математика', time: '9:00', teacher: 'Петрова П.П.', auditorium: 'каб. 102'),
    ],
    [],
  ];
  return days[dayIndex];
}

