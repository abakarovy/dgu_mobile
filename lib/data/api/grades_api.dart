import 'package:dio/dio.dart';

import '../../features/grades/domain/entities/grade_entity.dart';
import 'api_client.dart';

class GradesApi {
  GradesApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// GET /api/journal/grades/my
  Future<List<GradeEntity>> getMyGrades() async {
    final res = await _api.dio.get<dynamic>(
      '/journal/grades/my',
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    if (res.statusCode != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'Не удалось загрузить оценки',
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

    final grade = str(
      json['grade_value'] ??
          json['grade'] ??
          json['value'] ??
          json['mark'] ??
          json['score'],
    ).trim();

    final teacher = str(
      json['teacher_name'] ??
          json['teacher'] ??
          json['teacher_full_name'],
    ).trim();

    final gradeType = str(json['grade_type'] ?? json['type']).trim();
    final date = dt(json['date'] ?? json['created_at'] ?? json['graded_at']);

    return GradeEntity(
      subjectName: subject.isEmpty ? 'Дисциплина' : subject,
      grade: grade,
      gradeType: gradeType.isNotEmpty ? gradeType : null,
      date: date,
      // В текущем API teacher_name может быть пустым/0 — тогда показываем тип оценки.
      teacherName: teacher.isNotEmpty
          ? teacher
          : (gradeType.isNotEmpty ? gradeType : null),
    );
  }
}

