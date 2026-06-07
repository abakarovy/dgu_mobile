import 'package:dio/dio.dart';

import '../models/event_model.dart';
import '../../features/staff/domain/dashboard_stats_normalizer.dart';
import 'api_client.dart';
import 'api_error_parser.dart';
import 'api_exception.dart';

/// Staff-эндпоинты вне `/api/v1` (журнал, отделение, админка мероприятий и т.д.).
class StaffModulesApi {
  StaffModulesApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static Options get _json200 =>
      Options(validateStatus: (s) => s != null && s < 500);

  // --- Мероприятия (admin) ---

  Future<List<EventModel>> getEventsAdminList() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/mobile/events/admin/list',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseEventList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      final res = await _api.dio.delete<dynamic>(
        '/mobile/events/$id',
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 204) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Версии приложения ---

  Future<Map<String, dynamic>> getMobileReleaseAdmin() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/mobile-app-release/admin',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> updateMobileReleaseAdmin(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _api.dio.put<dynamic>(
        '/mobile-app-release/admin',
        data: body,
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : body;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Дашборд ---

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/admin/dashboard-stats',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      if (data is! Map) return {};
      return normalizeDashboardStats(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Журнал преподавателя ---

  Future<List<Map<String, dynamic>>> getJournalSubjectsMy() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/journal/subjects/my',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Материалы ---

  Future<List<Map<String, dynamic>>> getGroupMaterials(int groupId) async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/materials/group/$groupId',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Кабинет отделения ---

  Future<Map<String, dynamic>> getDepartmentMe() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/cabinet/department/me',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<DepartmentGroupsOverviewResult> getDepartmentGroupsOverview() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/cabinet/department/groups-overview',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return DepartmentGroupsOverviewResult.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDepartmentAnnouncements() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/cabinet/department/announcements',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> createDepartmentAnnouncement(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/cabinet/department/announcements',
        data: body,
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : body;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteDepartmentAnnouncement(int id) async {
    try {
      final res = await _api.dio.delete<dynamic>(
        '/cabinet/department/announcements/$id',
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 204) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Новости (admin list) ---

  Future<List<Map<String, dynamic>>> getNewsAdminList() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/news/admin/list',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Пользователи (admin) ---

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final res = await _api.dio.get<dynamic>('/users', options: _json200);
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/users',
        data: body,
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : body;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> updateUser(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _api.dio.put<dynamic>(
        '/users/$id',
        data: body,
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : body;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Деактивация пользователя (если DELETE недоступен на бэкенде).
  Future<void> deactivateUser(int id) async {
    try {
      final res = await _api.dio.delete<dynamic>(
        '/users/$id',
        options: _json200,
      );
      if (res.statusCode == 200 || res.statusCode == 204) return;
    } on DioException {
      // fallback ниже
    }
    await updateUser(id, {'is_active': false});
  }

  // --- Группы ---

  Future<List<Map<String, dynamic>>> getGroupsAdmin() async {
    try {
      final res = await _api.dio.get<dynamic>('/groups', options: _json200);
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getGroup(int id) async {
    try {
      final res = await _api.dio.get<dynamic>('/groups/$id', options: _json200);
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> getGroupStudents(int groupId) async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/groups/$groupId/students',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/groups',
        data: body,
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : body;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> updateGroup(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _api.dio.put<dynamic>(
        '/groups/$id',
        data: body,
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : body;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addStudentToGroup(int groupId, int studentId) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/groups/$groupId/students/$studentId',
        options: _json200,
      );
      if (res.statusCode != 200 &&
          res.statusCode != 201 &&
          res.statusCode != 204) {
        throw _bad(res);
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> removeStudentFromGroup(int groupId, int studentId) async {
    try {
      final res = await _api.dio.delete<dynamic>(
        '/groups/$groupId/students/$studentId',
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 204) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Модерация портфолио ---

  Future<List<Map<String, dynamic>>> getModerationPending() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/portfolio/admin/pending',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> patchModeration(int id, Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.patch<dynamic>(
        '/portfolio/admin/$id',
        data: body,
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Рассылка оценок (weekly-grades-digest) ---

  Map<String, dynamic> _weeklyDigestPeriodBody(Map<String, dynamic> raw) {
    final body = <String, dynamic>{};
    final from = raw['period_from'] ?? raw['from'];
    final to = raw['period_to'] ?? raw['to'];
    if (from != null && '$from'.trim().isNotEmpty) {
      body['period_from'] = from;
    }
    if (to != null && '$to'.trim().isNotEmpty) {
      body['period_to'] = to;
    }
    return body;
  }

  Future<Map<String, dynamic>> previewWeeklyGrades(
    Map<String, dynamic> query,
  ) async {
    try {
      final studentId = query['student_user_id'] ?? query['student_id'];
      final qp = <String, dynamic>{
        'student_user_id': studentId,
        ..._weeklyDigestPeriodBody(query),
      };
      final res = await _api.dio.get<dynamic>(
        '/admin/weekly-grades-digest/preview',
        queryParameters: qp,
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> sendWeeklyGrades(Map<String, dynamic> body) async {
    try {
      final studentId = body['student_user_id'] ?? body['student_id'];
      final payload = <String, dynamic>{
        'student_user_id': studentId,
        ..._weeklyDigestPeriodBody(body),
      };
      final res = await _api.dio.post<dynamic>(
        '/admin/weekly-grades-digest/send-student',
        data: payload,
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> sendWeeklyGradesBulk(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/admin/weekly-grades-digest/send-broadcast',
        data: _weeklyDigestPeriodBody(body),
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyGradesRecipients({
    String role = 'student',
    String? search,
  }) async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/admin/weekly-grades-digest/recipients',
        queryParameters: {
          'role': role,
          if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
        },
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Настройки ---

  Future<Map<String, dynamic>> getAdminSettings() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/admin/settings',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> patchAdminSettings(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _api.dio.patch<dynamic>(
        '/admin/settings',
        data: body,
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : body;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Сведения об ОО ---

  Future<List<Map<String, dynamic>>> getEduDisclosureAdminSections() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/edu-disclosure/admin/sections',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteNews(int id) async {
    try {
      final res = await _api.dio.delete<dynamic>(
        '/news/$id',
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 204) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Стипендиальный рейтинг (модерация) ---

  Future<List<Map<String, dynamic>>> getScholarshipRatingAdminPending() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/scholarship-rating/staff/pending',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> getScholarshipRatingAdminCompleted({
    String? search,
  }) async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/scholarship-rating/staff/approved',
        queryParameters: search?.trim().isNotEmpty == true
            ? {'q': search!.trim()}
            : null,
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      return _parseMapList(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> patchScholarshipRatingAdmin(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _api.dio.patch<dynamic>(
        '/scholarship-rating/staff/$id',
        data: body,
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteScholarshipRatingAdmin(int id) async {
    try {
      final res = await _api.dio.delete<dynamic>(
        '/scholarship-rating/staff/$id',
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 204) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  List<Map<String, dynamic>> _parseMapList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map && data['items'] is List)
        ? data['items'] as List
        : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<EventModel> _parseEventList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map && data['items'] is List)
        ? data['items'] as List
        : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  ApiException _bad(Response<dynamic> res) => ApiException(
    ApiErrorParser.fromResponseData(res.data) ?? 'Ошибка',
    res.statusCode,
  );
}

/// Ответ GET `/cabinet/department/groups-overview`.
class DepartmentGroupsOverviewResult {
  const DepartmentGroupsOverviewResult({
    required this.groups,
    this.summary,
  });

  final List<Map<String, dynamic>> groups;
  final Map<String, dynamic>? summary;

  factory DepartmentGroupsOverviewResult.fromJson(dynamic data) {
    if (data is List) {
      return DepartmentGroupsOverviewResult(
        groups: data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final rawGroups = map['groups'];
      final groups = rawGroups is List
          ? rawGroups
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      final summaryRaw = map['summary'];
      return DepartmentGroupsOverviewResult(
        groups: groups,
        summary: summaryRaw is Map
            ? Map<String, dynamic>.from(summaryRaw)
            : null,
      );
    }
    return const DepartmentGroupsOverviewResult(groups: []);
  }
}
