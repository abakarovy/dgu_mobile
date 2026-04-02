import 'package:dio/dio.dart';

import '../../features/grades/domain/entities/grade_entity.dart';
import 'api_client.dart';
import 'api_exception.dart';

class GradesApi {
  GradesApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// GET /api/journal/grades/my
  Future<List<GradeEntity>> getMyGrades() async {
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
    // Если API прислал grade_value=null, показываем это как "-" (чтобы строка не пропадала).
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
      // В текущем API teacher_name может быть пустым/0 — тогда показываем тип оценки.
      teacherName: teacher.isNotEmpty
          ? teacher
          : (gradeType.isNotEmpty ? gradeType : null),
      semester: semester.isNotEmpty ? semester : null,
    );
  }
}

