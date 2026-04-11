import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../features/grades/domain/entities/grade_entity.dart';
import '../services/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Плоский список оценок + порядок семестров из ответа 1С (`grades[].semester`).
class GradesBundle {
  const GradesBundle({required this.grades, required this.semesters});

  final List<GradeEntity> grades;

  /// Как в `sync-grades`: порядок блоков; для журнала — уникальные семестры из записей.
  final List<String> semesters;
}

class GradesApi {
  GradesApi({required ApiClient apiClient, required TokenStorage tokenStorage})
      : _api = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<int?> _studentIdFromToken() async {
    final raw = await _tokenStorage.getUserDataJson();
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final id = m['id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
    } catch (_) {}
    return null;
  }

  Future<bool> _isParentRoleFromToken() async {
    final raw = await _tokenStorage.getUserDataJson();
    if (raw == null || raw.isEmpty) return false;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return (m['role'] ?? '').toString().trim().toLowerCase() == 'parent';
    } catch (_) {
      return false;
    }
  }

  /// Сначала `GET /api/1c/sync-grades` (руководство backend), иначе журнал.
  Future<List<GradeEntity>> getMyGrades() async {
    final b = await loadMyGrades();
    return b.grades;
  }

  /// Как [getMyGrades], но дополнительно отдаёт порядок семестров из тела `sync-grades`.
  ///
  /// [studentIdOverride] — ID ребёнка для роли `parent` (иначе из токена — сам пользователь).
  Future<GradesBundle> loadMyGrades({int? studentIdOverride}) async {
    // Родитель без явного id ребёнка не должен бить 1С с `student_id` из JWT (id родителя → 400).
    if (studentIdOverride == null && await _isParentRoleFromToken()) {
      return const GradesBundle(grades: <GradeEntity>[], semesters: <String>[]);
    }
    final sid = studentIdOverride ?? await _studentIdFromToken();
    if (sid != null) {
      try {
        final res = await _api.dio.get<dynamic>(
          ApiConstants.oneCSyncGradesPath,
          queryParameters: {'student_id': sid},
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
        if (res.statusCode == 200) {
          final sems = semesterOrderFromSyncData(res.data);
          final list = _extractGradeMaps(res.data);
          if (list.isNotEmpty) {
            return GradesBundle(
              grades: list.map(_fromJson).toList(),
              semesters: sems,
            );
          }
          if (sems.isNotEmpty) {
            return GradesBundle(grades: const <GradeEntity>[], semesters: sems);
          }
        }
      } on DioException {
        // fallback ниже
      }
    }
    if (studentIdOverride != null) {
      // Родитель: журнал `grades/my` недоступен (403).
      return const GradesBundle(grades: <GradeEntity>[], semesters: <String>[]);
    }
    final journal = await _getJournalGradesMy();
    return GradesBundle(
      grades: journal,
      semesters: _uniqueSortedSemestersFromEntities(journal),
    );
  }

  static List<String> semesterOrderFromSyncData(dynamic data) {
    final map = _asStringKeyedMap(data);
    if (map == null) return const <String>[];
    final grades = map['grades'];
    if (grades is! List) return const <String>[];
    final out = <String>[];
    for (final e in grades) {
      if (e is! Map) continue;
      final s = (e['semester'] ?? '').toString().trim();
      if (s.isNotEmpty) out.add(s);
    }
    return out;
  }

  static List<String> _uniqueSortedSemestersFromEntities(List<GradeEntity> items) {
    final set = <String>{};
    for (final g in items) {
      final s = (g.semester ?? '').trim();
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// `GET /api/1c/final-grades?student_id=…` — итоговые оценки (см. руководство backend §11.2).
  /// Формат тела по возможности совпадает с [getMyGrades] / sync-grades.
  Future<List<GradeEntity>> getFinalGrades() async {
    final sid = await _studentIdFromToken();
    if (sid == null) return const <GradeEntity>[];
    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCFinalGradesPath,
        queryParameters: {'student_id': sid},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) return const <GradeEntity>[];
      final list = _extractGradeMaps(res.data);
      if (list.isEmpty) return const <GradeEntity>[];
      return list.map(_fromJson).toList();
    } on DioException {
      return const <GradeEntity>[];
    }
  }

  /// Бэкенд отдаёт `GET /api/1c/sync-grades` как
  /// `{ grades: [ { semester: "…", records: [ { subject, grade, type, date } ] } ] }`.
  /// Раньше брали верхний список как строки оценок — в UI было пусто.
  static List<Map<String, dynamic>> _extractGradeMaps(dynamic data) {
    final map = _asStringKeyedMap(data);
    if (map != null) {
      final nested = _flattenSyncGradesSemesters(map);
      if (nested.isNotEmpty) return nested;
    }
    if (data is List) {
      return data
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    if (map != null) {
      for (final k in ['grades', 'items', 'data', 'records', 'list']) {
        final v = map[k];
        if (v is List) {
          return v
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      }
    }
    return [];
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static List<Map<String, dynamic>> _flattenSyncGradesSemesters(Map<String, dynamic> data) {
    final grades = data['grades'];
    if (grades is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in grades) {
      if (e is! Map) continue;
      final semRow = Map<String, dynamic>.from(e);
      final semester = (semRow['semester'] ?? '').toString().trim();
      final records = semRow['records'];
      if (records is! List) continue;
      for (final r in records) {
        if (r is! Map) continue;
        final row = Map<String, dynamic>.from(r);
        if (semester.isNotEmpty && (row['semester'] == null || '${row['semester']}'.trim().isEmpty)) {
          row['semester'] = semester;
        }
        out.add(row);
      }
    }
    return out;
  }

  /// `GET /api/journal/grades/my` — запасной путь, если sync-grades пустой/недоступен.
  Future<List<GradeEntity>> _getJournalGradesMy() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/journal/grades/my',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }

      final data = res.data;
      final list = (data is List)
          ? data
          : (data is Map<String, dynamic> && data['items'] is List)
              ? (data['items'] as List)
              : <dynamic>[];

      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(_fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static GradeEntity _fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v is String) ? v : (v == null ? '' : '$v');
    DateTime? dt(dynamic v) => DateTime.tryParse(str(v));

    final subject = str(
      json['subject_name'] ??
          json['subject'] ??
          json['discipline'] ??
          json['name'],
    ).trim();

    final hasGradeValueKey = json.containsKey('grade_value');
    final rawGradeValue = json['grade_value'];
    final grade = str(
      rawGradeValue ??
          json['grade'] ??
          json['value'] ??
          json['mark'] ??
          json['score'],
    ).trim();
    final shownGrade =
        (grade.isEmpty && hasGradeValueKey && rawGradeValue == null) ? '-' : grade;

    final teacher = str(
      json['teacher_name'] ??
          json['teacher'] ??
          json['teacher_full_name'],
    ).trim();

    final gradeType = str(json['grade_type'] ?? json['type']).trim();
    final date = dt(json['date'] ?? json['created_at'] ?? json['graded_at']);
    final semester = str(json['semester'] ?? json['term'] ?? json['period']).trim();

    return GradeEntity(
      subjectName: subject.isEmpty ? 'Дисциплина' : subject,
      grade: shownGrade,
      gradeType: gradeType.isNotEmpty ? gradeType : null,
      date: date,
      teacherName: teacher.isNotEmpty
          ? teacher
          : (gradeType.isNotEmpty ? gradeType : null),
      semester: semester.isNotEmpty ? semester : null,
    );
  }
}
