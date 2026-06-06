import 'package:dgu_mobile/data/models/absences_detail.dart';

/// Нормализация и сортировка подписей семестра из 1С (`1 сем 2025-2026`).
abstract final class SemesterLabels {
  SemesterLabels._();

  static String normalize(String raw) {
    var s = raw
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase()
        .replaceAll('ё', 'е');
    s = s.replaceAll(RegExp(r'semest[eе]r', caseSensitive: false), 'сем');
    s = s.replaceAll(RegExp(r'\bsem\b'), 'сем');
    return s;
  }

  static bool equals(String? a, String? b) {
    final x = (a ?? '').trim();
    final y = (b ?? '').trim();
    if (x.isEmpty || y.isEmpty) return false;
    return normalize(x) == normalize(y);
  }

  /// Ключ сортировки: «2 сем 2025-2026» → 20252.
  static int? sortKey(String raw) {
    final t = normalize(raw);
    final m = RegExp(
      r'^(\d+)\s*сем\.?\s+(\d{4})\s*-\s*(\d{4})',
    ).firstMatch(t);
    if (m == null) return null;
    final semNum = int.tryParse(m.group(1)!);
    final yearStart = int.tryParse(m.group(2)!);
    if (semNum == null || yearStart == null) return null;
    return yearStart * 10 + semNum;
  }

  static int compareNewestFirst(String a, String b) {
    final ka = sortKey(a);
    final kb = sortKey(b);
    if (ka != null && kb != null) return kb.compareTo(ka);
    if (ka != null) return -1;
    if (kb != null) return 1;
    return b.compareTo(a);
  }

  /// Уникальные подписи, от нового семестра к старому.
  static List<String> uniqueSorted(Iterable<String> input) {
    final canonical = <String, String>{};
    for (final raw in input) {
      final label = raw.trim();
      if (label.isEmpty) continue;
      canonical.putIfAbsent(normalize(label), () => label);
    }
    final out = canonical.values.toList()..sort(compareNewestFirst);
    return out;
  }

  /// Каноническая подпись для нормализованного ключа (первая встреченная).
  static String canonicalLabel(String raw) => raw.trim();

  /// Семестр по дате занятия: сент–фев → 1 сем, март–авг → 2 сем.
  static String inferFromDate(DateTime date) {
    final y = date.year;
    final m = date.month;
    if (m >= 9) return '1 сем $y-${y + 1}';
    if (m >= 3) return '2 сем ${y - 1}-$y';
    return '1 сем ${y - 1}-$y';
  }
}

/// Календарный период семестра для привязки оценок по дате.
class SemesterPeriod {
  const SemesterPeriod({
    required this.label,
    required this.start,
    required this.end,
  });

  final String label;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }
}

/// Периоды семестров из пропусков / эвристика по подписи.
abstract final class SemesterPeriods {
  SemesterPeriods._();

  static DateTime? _parseDdMmYyyy(String raw) {
    final t = raw.trim();
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(t);
    if (m == null) return null;
    final day = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    final year = int.tryParse(m.group(3)!);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  /// Эвристика для «N сем YYYY-YYYY», если бэкенд не прислал `period`.
  static SemesterPeriod? inferFromLabel(String raw) {
    final label = raw.trim();
    if (label.isEmpty) return null;
    final t = SemesterLabels.normalize(label);
    final m = RegExp(r'^(\d+)\s*сем\.?\s+(\d{4})\s*-\s*(\d{4})').firstMatch(t);
    if (m == null) return null;
    final semNum = int.tryParse(m.group(1)!);
    final y1 = int.tryParse(m.group(2)!);
    final y2 = int.tryParse(m.group(3)!);
    if (semNum == null || y1 == null || y2 == null) return null;
    if (semNum == 1) {
      return SemesterPeriod(
        label: label,
        start: DateTime(y1, 9, 1),
        end: DateTime(y2, 1, 31),
      );
    }
    if (semNum == 2) {
      return SemesterPeriod(
        label: label,
        start: DateTime(y2, 2, 1),
        end: DateTime(y2, 7, 31),
      );
    }
    return null;
  }

  static SemesterPeriod? _fromAbsenceRow(AbsenceSemesterRow row) {
    final label = row.semester.trim();
    if (label.isEmpty) return null;
    final start = row.periodStart;
    final end = row.periodEnd;
    if (start != null && end != null) {
      return SemesterPeriod(label: label, start: start, end: end);
    }
    return inferFromLabel(label);
  }

  /// Список периодов: пропуски + подписи из оценок (без дубликатов).
  static List<SemesterPeriod> merge({
    List<AbsenceSemesterRow> absences = const [],
    Iterable<String> labels = const [],
  }) {
    final byNorm = <String, SemesterPeriod>{};
    for (final row in absences) {
      final p = _fromAbsenceRow(row);
      if (p == null) continue;
      byNorm.putIfAbsent(SemesterLabels.normalize(p.label), () => p);
    }
    for (final raw in labels) {
      final label = raw.trim();
      if (label.isEmpty) continue;
      final key = SemesterLabels.normalize(label);
      if (byNorm.containsKey(key)) continue;
      final p = inferFromLabel(label);
      if (p != null) byNorm[key] = p;
    }
    final out = byNorm.values.toList()
      ..sort((a, b) => SemesterLabels.compareNewestFirst(a.label, b.label));
    return out;
  }

  /// Семестр по дате оценки; `null`, если период не найден.
  static String? semesterForDate(DateTime date, List<SemesterPeriod> periods) {
    for (final p in periods) {
      if (p.contains(date)) return p.label;
    }
    return null;
  }

  static DateTime? parsePeriodDate(String raw) => _parseDdMmYyyy(raw);
}
