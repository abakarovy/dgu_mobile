import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';
import 'scholarship_catalog_flatten.dart';

/// Эндпоинты из MOBILE_STUDENT_MODULES_RU: LMS, объявления отделения, портфолио,
/// стипендиальный рейтинг, портал «Студентам» (см. актуальный .md в репозитории бэкенда).
class StudentServicesApi {
  StudentServicesApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static Options get _json200 => Options(validateStatus: (s) => s != null && s < 500);

  // --- LMS ---

  Future<List<Map<String, dynamic>>> lmsList() async {
    try {
      final res = await _api.dio.get<dynamic>('/lms', options: _json200);
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      final list = data is List ? data : <dynamic>[];
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> lmsCredential(int credId) async {
    try {
      final res = await _api.dio.get<dynamic>('/lms/$credId', options: _json200);
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> lmsSave({
    required String serviceName,
    required String login,
    required String password,
  }) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/lms',
        data: {'service_name': serviceName, 'login': login, 'password': password},
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Объявления отделения ---

  /// `StudentDepartmentAnnouncementOut`: `id`, `title`, `body`, `created_at`, `group_code`.
  /// Пустой `[]` при 200 — норма (в т.ч. группа не сопоставлена).
  Future<List<Map<String, dynamic>>> departmentAnnouncementsMy() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/students/department-announcements/my',
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      final list = data is List ? data : <dynamic>[];
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Портфолио ---

  Future<List<Map<String, dynamic>>> portfolioMy() async {
    try {
      final res = await _api.dio.get<dynamic>('/portfolio/my', options: _json200);
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      final list = data is List ? data : <dynamic>[];
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> portfolioMyComplete() async {
    try {
      final res = await _api.dio.get<dynamic>('/portfolio/my-complete', options: _json200);
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<double> portfolioRatingTotal() async {
    try {
      final res = await _api.dio.get<dynamic>('/portfolio/rating', options: _json200);
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      if (data is Map && data['total_points'] != null) {
        final v = data['total_points'];
        if (v is num) return v.toDouble();
        return double.tryParse('$v') ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> portfolioUpload({
    required String filePath,
    String? filename,
    String? description,
    String section = 'general',
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
        if (description != null && description.isNotEmpty) 'description': description,
        'section': section,
      });
      final res = await _api.dio.post<dynamic>(
        '/portfolio/upload',
        data: form,
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          contentType: 'multipart/form-data',
        ),
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> portfolioDeletePending(int portfolioId) async {
    try {
      final res = await _api.dio.delete<dynamic>(
        '/portfolio/my/$portfolioId',
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 204) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>?> portfolioShareStatus() async {
    try {
      final res = await _api.dio.get<dynamic>('/portfolio/share', options: _json200);
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> portfolioShareEnable() async {
    try {
      final res = await _api.dio.post<dynamic>('/portfolio/share/enable', options: _json200);
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> portfolioShareRegenerate() async {
    try {
      final res =
          await _api.dio.post<dynamic>('/portfolio/share/regenerate', options: _json200);
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> portfolioShareDisable() async {
    try {
      final res = await _api.dio.delete<dynamic>('/portfolio/share', options: _json200);
      if (res.statusCode != 200 && res.statusCode != 204) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Стипендиальный рейтинг ---

  /// Публичный каталог (JWT не обязателен; при наличии токена уходит как обычно).
  Future<List<Map<String, dynamic>>> scholarshipCatalog() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/scholarship-rating/catalog',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) throw _bad(res);
      return flattenScholarshipRatingCatalog(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// [semester] — номер семестра в API (`1` / `2`), строкой в query.
  Future<Map<String, dynamic>> scholarshipMySummary({
    required String academicYear,
    required String semester,
  }) async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/scholarship-rating/my/summary',
        queryParameters: {'academic_year': academicYear, 'semester': semester},
        options: _json200,
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> scholarshipUpload({
    required String academicYear,
    required String semester,
    required String criterionId,
    required String filePath,
    String? filename,
    String? optionKey,
    int? authorsCount,
    String? notes,
  }) async {
    try {
      final map = <String, dynamic>{
        'academic_year': academicYear,
        'semester': semester,
        'criterion_id': criterionId,
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      };
      if (optionKey != null) map['option_key'] = optionKey;
      if (authorsCount != null) map['authors_count'] = authorsCount;
      if (notes != null && notes.isNotEmpty) map['notes'] = notes;
      final form = FormData.fromMap(map);
      final res = await _api.dio.post<dynamic>(
        '/scholarship-rating/my/upload',
        data: form,
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          contentType: 'multipart/form-data',
        ),
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> scholarshipDeletePending(int entryId) async {
    try {
      final res = await _api.dio.delete<dynamic>(
        '/scholarship-rating/my/$entryId',
        options: _json200,
      );
      if (res.statusCode != 200 && res.statusCode != 204) throw _bad(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Портал «Студентам» (публичный снимок, JWT не обязателен) ---

  Future<Map<String, dynamic>> studentPortal() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/student-portal',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) throw _bad(res);
      final data = res.data;
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  DioException _bad(Response<dynamic> r) => DioException(
        requestOptions: r.requestOptions,
        response: r,
        type: DioExceptionType.badResponse,
      );
}
