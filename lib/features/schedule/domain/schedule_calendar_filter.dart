import '../data/schedule_lesson.dart';

/// День календаря без времени.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Пары «на сегодня» для главной: сначала точное совпадение даты, иначе ближайший
/// прошедший учебный день с тем же weekday, иначе ближайший будущий.
List<ScheduleLesson> filterScheduleForCalendarToday(
  List<ScheduleLesson> all, {
  DateTime? now,
}) {
  final today = dateOnly(now ?? DateTime.now());
  final todayIdx = (now ?? DateTime.now()).weekday - 1;

  final withDate = all.where((e) => e.lessonDate != null).toList();
  final undatedToday = all
      .where((e) => e.lessonDate == null && e.weekdayIndex == todayIdx)
      .toList();
  if (withDate.isEmpty) {
    final fb = _fallbackWeekdayOnly(all, todayIdx);
    return _sortedByPair([...fb, ...undatedToday]);
  }

  final exact = withDate
      .where((e) => dateOnly(e.lessonDate!) == today)
      .toList();
  if (exact.isNotEmpty) {
    return _sortedByPair([...exact, ...undatedToday]);
  }

  final sameWeekday =
      withDate.where((e) => e.weekdayIndex == todayIdx).toList();
  if (sameWeekday.isEmpty) {
    return _fallbackWeekdayOnly(all, todayIdx);
  }

  DateTime? bestPast;
  for (final e in sameWeekday) {
    final d = dateOnly(e.lessonDate!);
    if (d.isAfter(today)) continue;
    if (bestPast == null || d.isAfter(bestPast)) bestPast = d;
  }
  if (bestPast != null) {
    return _sortedByPair(
      sameWeekday.where((e) => dateOnly(e.lessonDate!) == bestPast).toList(),
    );
  }

  DateTime? bestFuture;
  for (final e in sameWeekday) {
    final d = dateOnly(e.lessonDate!);
    if (!d.isAfter(today)) continue;
    if (bestFuture == null || d.isBefore(bestFuture)) bestFuture = d;
  }
  if (bestFuture != null) {
    return _sortedByPair(
      sameWeekday.where((e) => dateOnly(e.lessonDate!) == bestFuture).toList(),
    );
  }

  return const <ScheduleLesson>[];
}

/// Экран недели: строки с [lessonDate] = выбранный день; плюс строки без даты с тем же weekday.
/// Если дат в данных нет — режим по индексу дня недели.
List<ScheduleLesson> lessonsForSelectedCalendarDay(
  List<ScheduleLesson> all,
  DateTime selectedDay,
) {
  final target = dateOnly(selectedDay);
  final idx = selectedDay.weekday - 1;
  final dated = all.where((e) => e.lessonDate != null).toList();
  final byDate =
      dated.where((e) => dateOnly(e.lessonDate!) == target).toList();
  final undatedSameWeekday =
      all.where((e) => e.lessonDate == null && e.weekdayIndex == idx).toList();
  if (dated.isNotEmpty) {
    return _sortedByPair([...byDate, ...undatedSameWeekday]);
  }
  return _fallbackWeekdayOnly(all, idx);
}

List<ScheduleLesson> _fallbackWeekdayOnly(List<ScheduleLesson> all, int todayIdx) {
  final filtered = all.where((e) => e.weekdayIndex == todayIdx).toList();
  if (filtered.isNotEmpty) return _sortedByPair(filtered);
  // Раньше при полном отсутствии weekdayIndex отдавали весь список — на воскресенье без пар
  // это показывало «все пары недели». Оставляем запасной путь только для коротких ответов без индексов.
  if (all.isNotEmpty &&
      all.length <= 24 &&
      all.every((e) => e.weekdayIndex == null)) {
    return _sortedByPair(all.toList());
  }
  return filtered;
}

/// Сортировка по номеру пары (для ответа `/1c/schedule` без фильтра по календарю).
List<ScheduleLesson> sortScheduleLessonsByPair(List<ScheduleLesson> list) =>
    _sortedByPair(list);

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
