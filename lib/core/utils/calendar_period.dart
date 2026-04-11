import 'package:flutter/material.dart';

/// Календарные диапазоны для экранов «Оценки» / «Пропуски».
abstract final class CalendarPeriod {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Число календарных дней от [start] до [end] включительно.
  static int inclusiveDays(DateTime start, DateTime end) {
    final s = dateOnly(start);
    final e = dateOnly(end);
    return e.difference(s).inDays + 1;
  }

  /// Понедельник–воскресенье, неделя календаря, содержащая [any].
  static DateTimeRange weekMonSunContaining(DateTime any) {
    final day = dateOnly(any);
    final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
    final sunday = monday.add(const Duration(days: 6));
    return DateTimeRange(start: monday, end: sunday);
  }

  static String formatDdMmYyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
