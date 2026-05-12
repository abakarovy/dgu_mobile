import 'package:dgu_mobile/core/utils/calendar_period.dart';

import 'entities/grade_entity.dart';

/// Строка журнала 1С с типом «пропуск» (может дублироваться по учебным часам).
bool gradeEntityIsJournalAbsenceRow(GradeEntity g) {
  final t = (g.gradeType ?? '').toLowerCase();
  return t.contains('пропуск');
}

String _absenceGroupKey(GradeEntity g) {
  final d = g.date!;
  final day = CalendarPeriod.dateOnly(d);
  final subj = g.subjectName.trim();
  final gt = (g.gradeType ?? '').trim();
  final gv = g.grade.trim();
  final tn = (g.teacherName ?? '').trim();
  return '$subj\x00${day.toIso8601String()}\x00$gt\x00$gv\x00$tn';
}

GradeEntity _mergeAbsenceGroup(List<GradeEntity> list) {
  final first = list.first;
  final n = list.length;
  if (n == 1) return first;
  final tn = (first.teacherName ?? '').trim();
  final mergedTeacher = tn.isEmpty
      ? '$n записей журнала за занятие'
      : '$tn · $n записей журнала';
  return GradeEntity(
    subjectName: first.subjectName,
    grade: first.grade,
    gradeType: first.gradeType,
    date: first.date,
    teacherName: mergedTeacher,
    semester: first.semester,
  );
}

/// Одна пара предмет+день+тип+оценка+преподаватель для «Пропуск» → одна сущность;
/// счётчик дублей отражается в [GradeEntity.teacherName] (как подпись к карточке).
/// Порядок строк совпадает с исходным: на месте первой записи группы — объединённая, остальные опущены.
List<GradeEntity> mergeJournalAbsenceRows(List<GradeEntity> grades) {
  final groups = <String, List<GradeEntity>>{};
  for (final g in grades) {
    if (!gradeEntityIsJournalAbsenceRow(g) || g.date == null) continue;
    final key = _absenceGroupKey(g);
    groups.putIfAbsent(key, () => <GradeEntity>[]).add(g);
  }
  final mergedByKey = <String, GradeEntity>{
    for (final e in groups.entries) e.key: _mergeAbsenceGroup(e.value),
  };
  final emitted = <String>{};
  final out = <GradeEntity>[];
  for (final g in grades) {
    if (!gradeEntityIsJournalAbsenceRow(g) || g.date == null) {
      out.add(g);
      continue;
    }
    final key = _absenceGroupKey(g);
    if (emitted.contains(key)) continue;
    emitted.add(key);
    out.add(mergedByKey[key]!);
  }
  return out;
}
