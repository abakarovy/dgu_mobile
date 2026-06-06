import 'entities/grade_entity.dart';
import 'semester_labels.dart';

/// Список семестров для фильтра — из журнала (как на сайте).
abstract final class JournalSemesterOptions {
  JournalSemesterOptions._();

  static String? _semesterForRow(GradeEntity g) {
    final fromApi = (g.semester ?? '').trim();
    if (fromApi.isNotEmpty) return fromApi;
    if (g.date != null) return SemesterLabels.inferFromDate(g.date!);
    return null;
  }

  /// Уникальные семестры, от более свежих к старым (по последней дате в журнале).
  static List<String> buildFromJournal(List<GradeEntity> journal) {
    final latestDateByNorm = <String, DateTime>{};
    final canonicalByNorm = <String, String>{};

    for (final g in journal) {
      final sem = _semesterForRow(g);
      if (sem == null || sem.isEmpty) continue;
      final norm = SemesterLabels.normalize(sem);

      final existing = canonicalByNorm[norm];
      if (existing == null || _preferLabel(sem, existing)) {
        canonicalByNorm[norm] = sem;
      }

      final d = g.date;
      if (d == null) continue;
      final prev = latestDateByNorm[norm];
      if (prev == null || d.isAfter(prev)) {
        latestDateByNorm[norm] = d;
      }
    }

    final entries = canonicalByNorm.entries.toList()
      ..sort((a, b) {
        final da = latestDateByNorm[a.key] ?? DateTime(2000);
        final db = latestDateByNorm[b.key] ?? DateTime(2000);
        final byDate = db.compareTo(da);
        if (byDate != 0) return byDate;
        return SemesterLabels.compareNewestFirst(a.value, b.value);
      });
    return entries.map((e) => e.value).toList();
  }

  static bool _preferLabel(String a, String b) {
    final aHasNum = RegExp(r'\d\s*сем', caseSensitive: false).hasMatch(a);
    final bHasNum = RegExp(r'\d\s*сем', caseSensitive: false).hasMatch(b);
    return aHasNum && !bHasNum;
  }

  /// Фильтр строк журнала по выбранному семестру (с выводом из даты).
  static bool rowMatchesSemester(GradeEntity g, String filter) {
    if (filter.isEmpty) return true;
    final sem = _semesterForRow(g);
    return sem != null && SemesterLabels.equals(sem, filter);
  }

  /// Фильтр строк final-grades: только явный semester, без даты.
  static bool sessionRowMatchesSemester(GradeEntity g, String filter) {
    if (filter.isEmpty) return true;
    final sem = (g.semester ?? '').trim();
    if (sem.isEmpty) return false;
    return SemesterLabels.equals(sem, filter);
  }
}

/// Разбор `GET /api/1c/final-grades` → строки зачётно-экзаменационной сессии.
abstract final class FinalGradesParser {
  FinalGradesParser._();

  static String str(dynamic v) => v is String ? v : (v == null ? '' : '$v');

  /// Подпись семестра из полей 1С (как на сайте).
  static String? semesterFromRow(Map<String, dynamic> json) {
    for (final key in [
      'semester',
      'Semester',
      'Семестр',
      'semester_label',
      'term',
      'period',
      'Period',
    ]) {
      final s = str(json[key]).trim();
      if (s.isNotEmpty) return s;
    }

    final yearRaw = str(
      json['academic_year'] ?? json['study_year'] ?? json['year'],
    ).trim();
    final halfRaw = str(
      json['half_year'] ?? json['study_semester'] ?? json['semester_num'],
    ).trim();

    if (yearRaw.isEmpty || halfRaw.isEmpty) return null;

    final half = int.tryParse(RegExp(r'\d+').firstMatch(halfRaw)?.group(0) ?? '');
    if (half != 1 && half != 2) return null;

    final years = RegExp(r'(20\d{2})\s*-\s*(20\d{2})').firstMatch(yearRaw);
    if (years != null) {
      return '$half сем ${years.group(1)}-${years.group(2)}';
    }
    final single = int.tryParse(RegExp(r'20\d{2}').firstMatch(yearRaw)?.group(0) ?? '');
    if (single != null) {
      if (half == 1) return '1 сем $single-${single + 1}';
      return '2 сем $single-${single + 1}';
    }
    return null;
  }

  static GradeEntity? toEntity(Map<String, dynamic> json) {
    final semester = semesterFromRow(json);
    if (semester == null || semester.trim().isEmpty) return null;

    final subject = str(
      json['subject_name'] ??
          json['subject'] ??
          json['Subject'] ??
          json['discipline'] ??
          json['Дисциплина'] ??
          json['name'],
    ).trim();

    final gradeType = str(
      json['control_type'] ??
          json['ControlType'] ??
          json['grade_type'] ??
          json['type'] ??
          json['Type'],
    ).trim();

    final hasGradeValueKey = json.containsKey('grade_value');
    final rawGradeValue = json['grade_value'];
    final grade = str(
      rawGradeValue ??
          json['grade'] ??
          json['Grade'] ??
          json['mark'] ??
          json['value'] ??
          json['score'],
    ).trim();
    final shownGrade =
        (grade.isEmpty && hasGradeValueKey && rawGradeValue == null) ? '-' : grade;

    final teacher = str(
      json['teacher_name'] ?? json['teacher'] ?? json['teacher_full_name'],
    ).trim();

    final date = DateTime.tryParse(
      str(json['date'] ?? json['created_at'] ?? json['graded_at']),
    );

    return GradeEntity(
      subjectName: subject.isEmpty ? 'Дисциплина' : subject,
      grade: shownGrade,
      gradeType: gradeType.isNotEmpty ? gradeType : null,
      date: date,
      teacherName: teacher.isNotEmpty ? teacher : null,
      semester: semester.trim(),
    );
  }

  static List<GradeEntity> parseItems(Iterable<Map<String, dynamic>> items) {
    return items.map(toEntity).whereType<GradeEntity>().toList();
  }
}
