import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../features/grades/domain/entities/grade_entity.dart';
import '../../features/grades/domain/final_grades_parser.dart';
import '../../features/grades/domain/semester_labels.dart';
import '../services/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Журнал + итоги сессии из двух независимых API (см. SESSION_GRADES.md).
class GradesBundle {
  const GradesBundle({
    required this.journalGrades,
    required this.sessionGrades,
    required this.semesters,
  });

  /// `GET /api/journal/grades/my` — текущие отметки (без сессионных типов).
  final List<GradeEntity> journalGrades;

  /// `GET /api/1c/final-grades` — зачётно-экзаменационная сессия.
  final List<GradeEntity> sessionGrades;

  /// Семестры для фильтра (из журнала; fallback — из final-grades).
  final List<String> semesters;

  /// Обратная совместимость: только журнал.
  List<GradeEntity> get grades => journalGrades;
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

  Future<List<GradeEntity>> getMyGrades() async {
    final b = await loadMyGrades();
    return b.journalGrades;
  }

  /// Параллельно: журнал + final-grades (`refresh=1`, как на сайте).
  ///
  /// [studentIdOverride] — для родителя (final-grades с `student_id`).
  Future<GradesBundle> loadMyGrades({int? studentIdOverride}) async {
    if (studentIdOverride == null && await _isParentRoleFromToken()) {
      return const GradesBundle(
        journalGrades: <GradeEntity>[],
        sessionGrades: <GradeEntity>[],
        semesters: <String>[],
      );
    }

    final sid = studentIdOverride ?? await _studentIdFromToken();
    final isParentChild = studentIdOverride != null;

    List<GradeEntity> journal = const [];
    List<GradeEntity> session = const [];

    if (!isParentChild) {
      try {
        journal = await _getJournalGradesMy(refresh: true);
      } on DioException {
        journal = const [];
      }
    }

    if (sid != null) {
      session = await _getFinalGrades(refresh: true, studentId: sid);
    }

    var semesters = JournalSemesterOptions.buildFromJournal(journal);
    if (semesters.isEmpty && session.isNotEmpty) {
      semesters = SemesterLabels.uniqueSorted(
        session.map((g) => (g.semester ?? '').trim()).where((s) => s.isNotEmpty),
      );
    }

    return GradesBundle(
      journalGrades: journal,
      sessionGrades: session,
      semesters: semesters,
    );
  }

  /// `GET /api/1c/final-grades` — итоговые ведомости сессии.
  Future<List<GradeEntity>> getFinalGrades({int? studentId}) async {
    final sid = studentId ?? await _studentIdFromToken();
    if (sid == null) return const <GradeEntity>[];
    return _getFinalGrades(refresh: true, studentId: sid);
  }

  Future<List<GradeEntity>> _getFinalGrades({
    required bool refresh,
    required int studentId,
  }) async {
    try {
      final qp = <String, dynamic>{
        'student_id': studentId,
        if (refresh) 'refresh': '1',
      };
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCFinalGradesPath,
        queryParameters: qp,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) return const <GradeEntity>[];
      final list = _extractFinalGradeMaps(res.data);
      if (list.isEmpty) return const <GradeEntity>[];
      return FinalGradesParser.parseItems(list);
    } on DioException {
      return const <GradeEntity>[];
    }
  }

  static List<Map<String, dynamic>> _extractFinalGradeMaps(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    final map = _asStringKeyedMap(data);
    if (map == null) return [];
    for (final k in ['grades', 'Grades', 'items', 'data', 'records']) {
      final v = map[k];
      if (v is List) {
        return v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      }
    }
    return [];
  }

  /// `GET /api/journal/grades/my` — журнал успеваемости.
  Future<List<GradeEntity>> _getJournalGradesMy({bool refresh = false}) async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/journal/grades/my',
        queryParameters: refresh ? {'refresh': '1'} : null,
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
          .map(_fromJournalJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static GradeEntity _fromJournalJson(Map<String, dynamic> json) {
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
    var semester = str(json['semester'] ?? json['term'] ?? json['period']).trim();
    if (semester.isEmpty && date != null) {
      semester = SemesterLabels.inferFromDate(date);
    }

    return GradeEntity(
      subjectName: subject.isEmpty ? 'Дисциплина' : subject,
      grade: shownGrade,
      gradeType: gradeType.isNotEmpty ? gradeType : null,
      date: date,
      teacherName: teacher.isNotEmpty ? teacher : null,
      semester: semester.isNotEmpty ? semester : null,
    );
  }
}
