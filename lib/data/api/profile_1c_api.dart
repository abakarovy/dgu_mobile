import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/absences_detail.dart';
import '../models/one_c_my_profile.dart';
import '../services/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// `GET /api/1c/my-profile` — профиль студента из 1С.
class Profile1cApi {
  Profile1cApi({required ApiClient apiClient, required TokenStorage tokenStorage})
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

  /// [studentId] — для роли `parent`: ID ребёнка (см. `GET /api/1c/my-profile?student_id=`).
  Future<OneCMyProfile> getMyProfile({int? studentId}) async {
    try {
      final qp = <String, dynamic>{'mobile': 'true'};
      if (studentId != null) qp['student_id'] = studentId;
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCMyProfilePath,
        queryParameters: qp,
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final raw = res.data;
      final map = _unwrapToMap(raw);
      if (map == null) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      return OneCMyProfile.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Фото студента (бинарный файл) через `GET /api/1c/student-photo`.
  ///
  /// - Возвращает `null`, если фото не найдено (`404`) или зачётки нет (`400`).
  /// - Для роли `parent` требуется `studentId` (см. backend doc).
  Future<List<int>?> getStudentPhotoBytes({int? studentId}) async {
    try {
      final qp = <String, dynamic>{};
      if (studentId != null) qp['student_id'] = studentId;
      final res = await _api.dio.get<List<int>>(
        ApiConstants.oneCStudentPhotoPath,
        queryParameters: qp.isEmpty ? null : qp,
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          responseType: ResponseType.bytes,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      final code = res.statusCode ?? 0;
      if (code == 404 || code == 400) return null;
      if (code != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) return null;
      return bytes;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Учебный план: `GET /api/1c/curriculum?student_id=` (см. руководство мобильного клиента).
  /// [studentId] — для родителя: ID ребёнка; иначе берётся из токена.
  Future<Object?> getCurriculum({int? studentId}) async {
    final sid = studentId ?? await _studentIdFromToken();
    if (sid == null) return null;
    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCCurriculumPath,
        queryParameters: {'student_id': sid},
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) return null;
      return res.data;
    } on DioException {
      return null;
    }
  }

  /// `GET /api/1c/absences?student_id=&start=&end=` — пропуски: `semesters[].data.total_absences`
  /// (опционально [currentSemester] — совпадение с текущим семестром из оценок).
  /// [start] / [end] — период в формате, который ожидает backend (часто `YYYY-MM-DD`).
  Future<String?> getAbsencesDisplayLabel({
    String? currentSemester,
    String? start,
    String? end,
    int? studentId,
  }) async {
    final sid = studentId ?? await _studentIdFromToken();
    if (sid == null) return null;
    try {
      final qp = <String, dynamic>{'student_id': sid};
      final s = start?.trim();
      final e = end?.trim();
      if (s != null && s.isNotEmpty) qp['start'] = s;
      if (e != null && e.isNotEmpty) qp['end'] = e;
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCAbsencesPath,
        queryParameters: qp,
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) return null;
      final fromSemesters = _parseAbsencesFromSemesters(res.data, currentSemester: currentSemester);
      if (fromSemesters != null) return fromSemesters;
      final hours = _parseTotalHours(res.data);
      if (hours == null) return null;
      return _formatHoursRu(hours);
    } on DioException {
      return null;
    }
  }

  /// Полный ответ пропусков: семестры и опционально список записей.
  Future<AbsencesDetail?> getAbsencesDetail({int? studentId}) async {
    final sid = studentId ?? await _studentIdFromToken();
    if (sid == null) return null;
    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCAbsencesPath,
        queryParameters: {'student_id': sid},
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) return null;
      return _parseAbsencesDetail(res.data);
    } on DioException {
      return null;
    }
  }

  static AbsencesDetail _parseAbsencesDetail(dynamic raw) {
    if (raw is! Map) {
      return const AbsencesDetail(semesters: []);
    }
    final map = Map<String, dynamic>.from(raw);
    final semesters = <AbsenceSemesterRow>[];
    final sems = map['semesters'];
    if (sems is List) {
      for (final e in sems) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final label = m['semester']?.toString().trim() ?? '';
        Map<String, dynamic>? d;
        if (m['data'] is Map) {
          d = Map<String, dynamic>.from(m['data'] as Map);
        }
        int? abs;
        double? hrs;
        if (d != null) {
          abs = _asInt(d['total_absences']);
          hrs = _asDouble(d['total_hours'] ?? d['hours'] ?? d['sum_hours'] ?? d['hours_total']);
        }
        int? y = _asInt(m['year'] ?? m['study_year']);
        semesters.add(
          AbsenceSemesterRow(
            semester: label,
            year: y,
            totalAbsences: abs,
            totalHours: hrs,
          ),
        );
      }
    }
    final items = <Map<String, dynamic>>[];
    final rawItems = map['items'] ?? map['absences'];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) items.add(Map<String, dynamic>.from(e));
      }
    }
    return AbsencesDetail(semesters: semesters, items: items);
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static String? _parseAbsencesFromSemesters(dynamic raw, {String? currentSemester}) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final sems = map['semesters'];
    if (sems is! List || sems.isEmpty) return null;
    final cur = currentSemester?.trim();
    if (cur != null && cur.isNotEmpty) {
      for (final e in sems) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        if ((m['semester']?.toString().trim() ?? '') != cur) continue;
        final d = m['data'];
        if (d is Map) {
          final n = _asInt(d['total_absences']);
          if (n != null) return _formatAbsencesRu(n);
        }
      }
    }
    final first = sems.first;
    if (first is Map) {
      final d = first['data'];
      if (d is Map) {
        final n = _asInt(d['total_absences']);
        if (n != null) return _formatAbsencesRu(n);
      }
    }
    return null;
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static String _formatAbsencesRu(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return '$n пропусков';
    if (mod10 == 1) return '$n пропуск';
    if (mod10 >= 2 && mod10 <= 4) return '$n пропуска';
    return '$n пропусков';
  }

  static double? _parseTotalHours(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is Map<String, dynamic>) {
      for (final k in [
        'total_hours',
        'hours_total',
        'sum_hours',
        'hours',
        'total',
      ]) {
        final v = raw[k];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      }
      final nested = raw['summary'];
      if (nested is Map<String, dynamic>) {
        final h = _parseTotalHours(nested);
        if (h != null) return h;
      }
      final items = raw['items'] ?? raw['absences'] ?? raw['data'];
      if (items is List) {
        double sum = 0;
        var any = false;
        for (final e in items) {
          if (e is Map<String, dynamic>) {
            final h = e['hours'] ?? e['duration_hours'] ?? e['count_hours'];
            if (h is num) {
              sum += h.toDouble();
              any = true;
            }
          }
        }
        if (any) return sum;
      }
    }
    return null;
  }

  static String _formatHoursRu(double hours) {
    final v = hours.round();
    final mod10 = v % 10;
    final mod100 = v % 100;
    if (mod100 >= 11 && mod100 <= 14) return '$v часов';
    if (mod10 == 1) return '$v час';
    if (mod10 >= 2 && mod10 <= 4) return '$v часа';
    return '$v часов';
  }

  /// `GET /api/1c/group-list?student_id=`
  Future<Object?> getGroupList() async {
    final sid = await _studentIdFromToken();
    if (sid == null) return null;
    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCGroupListPath,
        queryParameters: {'student_id': sid},
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) return null;
      return res.data;
    } on DioException {
      return null;
    }
  }

  /// `GET /api/1c/practices?student_id=`
  Future<Object?> getPractices() async {
    final sid = await _studentIdFromToken();
    if (sid == null) return null;
    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCPracticesPath,
        queryParameters: {'student_id': sid},
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) return null;
      return res.data;
    } on DioException {
      return null;
    }
  }

  /// Кураторские часы в 1С: `GET /api/1c/events?student_id=` (не мероприятия колледжа).
  Future<Object?> getOneCCuratorEvents() async {
    final sid = await _studentIdFromToken();
    if (sid == null) return null;
    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCCuratorEventsPath,
        queryParameters: {'student_id': sid},
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: ApiConstants.scheduleReceiveTimeout,
        ),
      );
      if (res.statusCode != 200) return null;
      return res.data;
    } on DioException {
      return null;
    }
  }

  static Map<String, dynamic>? _unwrapToMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final profile = raw['profile'];
      if (profile is Map<String, dynamic>) return profile;
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    return null;
  }
}
