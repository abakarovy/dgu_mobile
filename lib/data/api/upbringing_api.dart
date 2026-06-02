import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Воспитательная деятельность (`GET /api/upbringing`).
class UpbringingApi {
  UpbringingApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const cacheKey = 'applicant:upbringing';

  Future<Map<String, dynamic>> getUpbringing() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/upbringing',
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
