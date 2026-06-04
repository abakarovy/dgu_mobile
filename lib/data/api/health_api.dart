import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/device/app_runtime_info.dart';
import '../models/app_health_response.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// `GET /api/health` — статус API, телеметрия клиента, политика обновления.
class HealthApi {
  HealthApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<AppHealthResponse?> check() async {
    await AppRuntimeInfo.instance.ensureLoaded();
    final query = AppRuntimeInfo.instance.toHealthQueryParameters();

    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.healthPath,
        queryParameters: query,
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          headers: {
            'X-App-Version': query['app_version'],
            'X-App-Platform': query['platform'],
            'X-Device-Model': query['device_model'],
          },
        ),
      );
      if (res.statusCode != 200) return null;
      final data = res.data;
      final map = (data is Map<String, dynamic>)
          ? data
          : (data is Map)
              ? Map<String, dynamic>.from(data)
              : null;
      if (map == null) return null;
      return AppHealthResponse.fromJson(map);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      throw ApiException.fromDio(e);
    }
  }
}
