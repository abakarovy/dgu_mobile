import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/device/app_runtime_info.dart';
import '../../core/logging/app_log_file.dart';
import '../models/app_health_response.dart';
import 'api_client.dart';

/// `GET /api/health` — статус API, телеметрия клиента, политика обновления.
class HealthApi {
  HealthApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<AppHealthResponse?> check() async {
    await AppRuntimeInfo.instance.ensureLoaded();
    final info = AppRuntimeInfo.instance;
    final query = Map<String, String>.from(info.toHealthQueryParameters());

    // В debug на desktop сервер не отдаёт `app_update` для windows — проверяем как android.
    if (kDebugMode && !info.isMobileStorePlatform) {
      query['platform'] = 'android';
    }

    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.healthPath,
        queryParameters: query,
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          // Только ASCII: иначе Dio на Windows падает (DioExceptionType.unknown).
          headers: {
            'X-App-Version': query['app_version'],
            'X-App-Platform': query['platform'],
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
      if (!kReleaseMode) {
        AppLogFile.writeln('[health] ошибка: ${e.type} ${e.message}');
      }
      return null;
    } catch (e, st) {
      if (!kReleaseMode) {
        AppLogFile.writeln('[health] ошибка: $e');
        AppLogFile.writeln('$st');
      }
      return null;
    }
  }
}
