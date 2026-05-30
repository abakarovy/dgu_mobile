import '../data/schedule_lesson.dart';

/// Заглушка от 1С/бэка вместо пустого списка («В этот день пар нет» и т.п.).
bool isSchedulePlaceholderLesson(ScheduleLesson lesson) {
  final subject = lesson.subject.trim().toLowerCase();
  if (subject.isEmpty) return false;

  if (RegExp(r'нет\s*пар|пар\s*нет|занятий\s*нет|нет\s*занятий').hasMatch(subject)) {
    return true;
  }

  final time = lesson.time.trim();
  final hasClockTime = RegExp(r'\d{1,2}:\d{2}').hasMatch(time);
  if (!hasClockTime && subject.contains('этот день')) {
    return true;
  }

  return false;
}

List<ScheduleLesson> withoutSchedulePlaceholders(List<ScheduleLesson> list) =>
    list.where((e) => !isSchedulePlaceholderLesson(e)).toList(growable: false);

/// День календаря без времени.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Пары на календарный день [now] (по умолчанию сегодня): только точное совпадение [lessonDate]
/// и строки без даты с тем же днём недели. Без подстановки занятий с других дат.
List<ScheduleLesson> filterScheduleForCalendarToday(
  List<ScheduleLesson> all, {
  DateTime? now,
}) {
  all = withoutSchedulePlaceholders(all);
  final day = dateOnly(now ?? DateTime.now());
  final dayIdx = (now ?? DateTime.now()).weekday - 1;

  final undatedThisWeekday = all
      .where((e) => e.lessonDate == null && e.weekdayIndex == dayIdx)
      .toList();
  final dated = all.where((e) => e.lessonDate != null).toList();

  if (dated.isEmpty) {
    return _sortedByPair(undatedThisWeekday);
  }

  final exact =
      dated.where((e) => dateOnly(e.lessonDate!) == day).toList();
  return _sortedByPair([...exact, ...undatedThisWeekday]);
}

/// Экран недели: только [lessonDate] = выбранный день; плюс строки без даты с тем же weekday.
/// Без подстановки пар с других дат.
List<ScheduleLesson> lessonsForSelectedCalendarDay(
  List<ScheduleLesson> all,
  DateTime selectedDay,
) {
  all = withoutSchedulePlaceholders(all);
  final target = dateOnly(selectedDay);
  final idx = selectedDay.weekday - 1;
  final undatedSameWeekday =
      all.where((e) => e.lessonDate == null && e.weekdayIndex == idx).toList();
  final dated = all.where((e) => e.lessonDate != null).toList();

  if (dated.isEmpty) {
    return _sortedByPair(undatedSameWeekday);
  }

  final byDate =
      dated.where((e) => dateOnly(e.lessonDate!) == target).toList();
  return _sortedByPair([...byDate, ...undatedSameWeekday]);
}

/// Сортировка по номеру пары (для ответа `/1c/schedule` без фильтра по календарю).
List<ScheduleLesson> sortScheduleLessonsByPair(List<ScheduleLesson> list) =>
    _sortedByPair(withoutSchedulePlaceholders(list));

List<ScheduleLesson> _sortedByPair(List<ScheduleLesson> list) {
  final copy = [...list];
  copy.sort((a, b) {
    final pa = a.pairNumber ?? 9999;
    final pb = b.pairNumber ?? 9999;
    final c = pa.compareTo(pb);
    if (c != 0) return c;
    return a.time.compareTo(b.time);
  });
  return copy;
}
