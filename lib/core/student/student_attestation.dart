import 'package:dgu_mobile/features/grades/domain/entities/grade_entity.dart';

/// Окно аттестации (границы включительно, даты в локальном календаре).
/// Правила совпадают с `getAttestationWindow` на веб-клиенте (см. MOBILE_RETAKE_ANNOUNCEMENTS.md).
class AttestationWindow {
  const AttestationWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

/// Категория для дедупликации: не более одной карточки на предмет в каждой категории.
enum RetakeDedupeCategory {
  absence,
  failCredit,
  unsatisfactory,
}

/// Подсказка «пересдача» по строке журнала за текущее окно аттестации.
class RetakeHint {
  const RetakeHint({
    required this.subjectName,
    required this.detailText,
    required this.category,
  });

  final String subjectName;
  final String detailText;
  final RetakeDedupeCategory category;
}

AttestationWindow getAttestationWindow(DateTime now) {
  final local = DateTime(now.year, now.month, now.day);
  final y = local.year;
  final m = local.month;

  final academicStartYear = m >= 9 ? y : y - 1;

  DateTime d(int year, int month, int day) => DateTime(year, month, day);

  if (m >= 9 && m <= 10) {
    return AttestationWindow(d(academicStartYear, 9, 1), d(academicStartYear, 10, 31));
  }
  if (m == 11 || m == 12) {
    return AttestationWindow(d(academicStartYear, 11, 1), d(academicStartYear, 12, 31));
  }
  if (m == 1) {
    return AttestationWindow(d(y - 1, 12, 1), d(y, 1, 31));
  }
  if (m >= 2 && m <= 3) {
    return AttestationWindow(d(y, 2, 1), d(y, 3, 31));
  }
  if (m >= 4 && m <= 5) {
    return AttestationWindow(d(y, 4, 1), d(y, 5, 31));
  }
  // Июнь–август: то же весеннее окно апрель–май текущего календарного года.
  return AttestationWindow(d(y, 4, 1), d(y, 5, 31));
}

bool gradeDateInAttestationWindow(DateTime? gradeDate, DateTime now) {
  if (gradeDate == null) return false;
  final w = getAttestationWindow(now);
  final d = DateTime(gradeDate.year, gradeDate.month, gradeDate.day);
  return !d.isBefore(w.start) && !d.isAfter(w.end);
}

/// Аналог `gradeMarkRequiresRetakeHint` с веб-клиента: неуспех / неявка / незачёт.
bool gradeMarkRequiresRetakeHint(String gradeRaw, String? gradeTypeRaw) {
  final g = gradeRaw.trim();
  if (g.isEmpty || g == '-') return false;

  final lower = g.toLowerCase();
  final type = (gradeTypeRaw ?? '').trim().toLowerCase();
  final blob = '$lower $type'.trim();

  if (lower == 'н' || lower == 'н/б' || lower == 'н/а') return true;

  final n = int.tryParse(g);
  if (n != null) {
    if (n == 2) return true;
    if (n >= 3 && n <= 5) return false;
  }

  if (_isExplicitPass(blob)) return false;

  if (_containsFailUnsatisfactory(blob)) return true;
  if (_containsFailAttestation(blob)) return true;
  if (_containsFailCredit(blob)) return true;
  if (_containsAbsence(blob)) return true;

  return false;
}

bool _isExplicitPass(String blob) {
  if (RegExp(r'отличн').hasMatch(blob)) return true;
  if (RegExp(r'\bхор\b').hasMatch(blob) || RegExp(r'хорош').hasMatch(blob)) return true;
  if (blob.contains('удовлетворительно') && !blob.contains('неудовлетворительно')) return true;
  if (RegExp(r'\bудовл').hasMatch(blob) && !blob.contains('неуд')) return true;
  if (RegExp(r'зач[ёе]т').hasMatch(blob) && !blob.contains('незач') && !blob.contains('не зач')) {
    return true;
  }
  if (blob.contains('зачтено')) return true;
  return false;
}

bool _containsFailUnsatisfactory(String blob) {
  if (blob.contains('неудовлетворительно')) return true;
  if (blob.contains('не удовлетворительно')) return true;
  if (RegExp(r'неуд\b').hasMatch(blob)) return true;
  if (blob.contains('не атт') || blob.contains('неатт')) return true;
  return false;
}

bool _containsFailAttestation(String blob) {
  return blob.contains('неаттест');
}

bool _containsFailCredit(String blob) {
  return blob.contains('незач') || blob.contains('не зач');
}

bool _containsAbsence(String blob) {
  if (blob.contains('неяв') || blob.contains('не яв')) return true;
  if (blob.contains('неявк')) return true;
  if (blob.contains('н/б') || blob.contains('н/а')) return true;
  return false;
}

RetakeDedupeCategory? retakeDedupeCategoryForGrade(String gradeRaw, String? gradeTypeRaw) {
  if (!gradeMarkRequiresRetakeHint(gradeRaw, gradeTypeRaw)) return null;
  final lower = gradeRaw.trim().toLowerCase();
  final type = (gradeTypeRaw ?? '').trim().toLowerCase();
  final blob = '$lower $type';

  if (lower == 'н' || lower == 'н/б' || lower == 'н/а') {
    return RetakeDedupeCategory.absence;
  }
  if (_containsAbsence(blob)) {
    return RetakeDedupeCategory.absence;
  }
  if (_containsFailCredit(blob)) {
    return RetakeDedupeCategory.failCredit;
  }
  return RetakeDedupeCategory.unsatisfactory;
}

/// Аналог `retakeHintDetailForRow` на вебе.
String retakeHintDetailForRow({
  required String gradeRaw,
  required String? gradeTypeRaw,
  required RetakeDedupeCategory category,
}) {
  switch (category) {
    case RetakeDedupeCategory.absence:
      return 'По журналу зафиксирована неявка на аттестацию — уточните срок пересдачи в отделении.';
    case RetakeDedupeCategory.failCredit:
      return 'По журналу зафиксирован незачёт — необходимо сдать дисциплину в срок пересдачи.';
    case RetakeDedupeCategory.unsatisfactory:
      final t = (gradeTypeRaw ?? '').trim();
      final label = t.isNotEmpty ? t : 'Итог';
      return '$label: неудовлетворительно';
  }
}

/// Тип строки журнала — итоговый **зачёт** или **экзамен** (для блока на экране объявлений).
bool isDepartmentJournalExamOrCreditType(String? gradeTypeRaw) {
  final t = (gradeTypeRaw ?? '').trim().toLowerCase();
  if (t.isEmpty) return false;
  if (t.contains('пропуск')) return false;
  if (t.contains('ответ у доски')) return false;
  if (t.contains('контрольн')) return false;
  if (t.contains('к/р')) return false;
  if (t.contains('практическ')) return false;
  if (t.contains('юрайт')) return false;
  if (t.contains('опрос')) return false;
  if (t.contains('курсов')) return false;
  if (t.contains('экзам')) return true;
  if (t.contains('зач')) return true;
  return false;
}

/// Строит подсказки по оценкам за текущее окно аттестации (локальное «сейчас»).
List<RetakeHint> buildRetakeHintsFromGrades(
  List<GradeEntity> grades, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final seen = <String, bool>{};
  final out = <RetakeHint>[];

  for (final e in grades) {
    if (!gradeDateInAttestationWindow(e.date, clock)) continue;
    if (!gradeMarkRequiresRetakeHint(e.grade, e.gradeType)) continue;

    final cat = retakeDedupeCategoryForGrade(e.grade, e.gradeType);
    if (cat == null) continue;

    final subject = e.subjectName.trim().isEmpty ? 'Дисциплина' : e.subjectName.trim();
    final key = '$subject|${cat.name}';
    if (seen.containsKey(key)) continue;
    seen[key] = true;

    out.add(
      RetakeHint(
        subjectName: subject,
        detailText: retakeHintDetailForRow(
          gradeRaw: e.grade,
          gradeTypeRaw: e.gradeType,
          category: cat,
        ),
        category: cat,
      ),
    );
  }

  return out;
}

/// Только **зачёт** / **экзамен** с неудовлетворительной оценкой (без неявок, без «незачёт» и т.п.).
/// Тексты короткие — для красной строки на экране объявлений отделения.
List<RetakeHint> buildDepartmentRetakeHints(
  List<GradeEntity> grades, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final seen = <String>{};
  final out = <RetakeHint>[];

  for (final e in grades) {
    if (!gradeDateInAttestationWindow(e.date, clock)) continue;
    if (!isDepartmentJournalExamOrCreditType(e.gradeType)) continue;
    if (!gradeMarkRequiresRetakeHint(e.grade, e.gradeType)) continue;

    final cat = retakeDedupeCategoryForGrade(e.grade, e.gradeType);
    if (cat == null ||
        cat == RetakeDedupeCategory.absence ||
        cat == RetakeDedupeCategory.failCredit) {
      continue;
    }

    final subject = e.subjectName.trim().isEmpty ? 'Дисциплина' : e.subjectName.trim();
    final tl = (e.gradeType ?? '').toLowerCase();
    final isExam = tl.contains('экзам');
    final kind = isExam ? 'e' : 'z';
    final key = '$subject|$kind';
    if (seen.contains(key)) continue;
    seen.add(key);

    final detail = isExam ? 'Экзамен — пересдача' : 'Зачёт — неудовлетворительно';

    out.add(
      RetakeHint(
        subjectName: subject,
        detailText: detail,
        category: RetakeDedupeCategory.unsatisfactory,
      ),
    );
  }

  return out;
}
