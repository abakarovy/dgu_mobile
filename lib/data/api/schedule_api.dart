import 'package:dio/dio.dart';

import '../../features/schedule/data/schedule_lesson.dart';
import 'api_client.dart';

class ScheduleApi {
  ScheduleApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// GET /api/1c/schedule (новый основной)
  Future<List<ScheduleLesson>> getWeek({String? week}) async {
    final res = await _api.dio.get<dynamic>(
      '/1c/schedule',
      queryParameters: {
        if (week != null && week.trim().isNotEmpty) 'week': week.trim(),
      },
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    if (res.statusCode != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'Не удалось загрузить расписание',
      );
    }
    return _parseSchedule(res.data);
  }

  /// GET /api/1c/schedule/today
  Future<List<ScheduleLesson>> getToday() async {
    final res = await _api.dio.get<dynamic>(
      '/1c/schedule/today',
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    if (res.statusCode != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'Не удалось загрузить расписание',
      );
    }
    return _parseSchedule(res.data);
  }

  List<ScheduleLesson> _parseSchedule(dynamic data) {
    final list = (data is List)
        ? data
        : (data is Map<String, dynamic> && data['schedule'] is List)
            ? (data['schedule'] as List)
            : (data is Map<String, dynamic> && data['items'] is List)
                ? (data['items'] as List)
                : <dynamic>[];

    return list
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(_lessonFromJson)
        .toList();
  }

  static ScheduleLesson _lessonFromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v is String) ? v : (v == null ? '' : '$v');

    final dayShort = str(json['day_short']).toLowerCase().trim();
    final weekdayIndex = switch (dayShort) {
      'пн' => 0,
      'вт' => 1,
      'ср' => 2,
      'чт' => 3,
      'пт' => 4,
      'сб' => 5,
      'вс' => 6,
      _ => null,
    };

    final subject = str(
      json['subject'] ??
          json['discipline'] ??
          json['name'] ??
          json['title'] ??
          json['lesson_name'],
    ).trim();

    final teacher = str(
      json['teacher'] ??
          json['teacher_name'] ??
          json['lecturer'] ??
          json['professor'],
    ).trim();

    final room = str(
      json['auditorium'] ??
          json['room'] ??
          json['cabinet'] ??
          json['classroom'],
    ).trim();

    final start = str(json['start_time'] ?? json['start'] ?? json['time_start']).trim();
    final end = str(json['end_time'] ?? json['end'] ?? json['time_end']).trim();
    final timeSingle = str(json['time'] ?? json['lesson_time']).trim();
    final time = (start.isNotEmpty && end.isNotEmpty)
        ? '$start—$end'
        : (timeSingle.isNotEmpty ? timeSingle : start);

    return ScheduleLesson(
      weekdayIndex: weekdayIndex,
      subject: subject.isEmpty ? 'Пара' : subject,
      time: time.isEmpty ? '--:--' : time,
      teacher: teacher.isEmpty ? '—' : teacher,
      auditorium: room.isEmpty ? '—' : room,
    );
  }
}

