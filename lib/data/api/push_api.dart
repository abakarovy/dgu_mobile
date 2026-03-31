import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

class PushApi {
  PushApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// POST /api/push/device
  Future<void> registerDevice({required String token, required String platform}) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/push/device',
        data: {'token': token, 'platform': platform},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /api/push/device
  Future<void> unregisterDevice({required String token}) async {
    try {
      final res = await _api.dio.delete<dynamic>(
        '/push/device',
        data: {'token': token},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

