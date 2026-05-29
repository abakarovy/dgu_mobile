import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Публичные сведения об образовательной организации (`GET /api/edu-disclosure`).
class EduDisclosureApi {
  EduDisclosureApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const cacheKey = 'applicant:edu-disclosure';

  Future<Map<String, dynamic>> getDisclosure() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/edu-disclosure',
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
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
