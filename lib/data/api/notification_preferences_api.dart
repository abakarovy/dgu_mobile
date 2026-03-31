import 'package:dio/dio.dart';

import '../models/notification_preferences_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

class NotificationPreferencesApi {
  NotificationPreferencesApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// GET /api/mobile/notification-preferences
  Future<NotificationPreferencesModel> getMy() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/mobile/notification-preferences',
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
      final map = (data is Map<String, dynamic>)
          ? data
          : (data is Map)
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
      return NotificationPreferencesModel.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PATCH /api/mobile/notification-preferences
  Future<NotificationPreferencesModel> patch(NotificationPreferencesModel patch) async {
    try {
      final res = await _api.dio.patch<dynamic>(
        '/mobile/notification-preferences',
        data: patch.toPatchJson(),
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
      final map = (data is Map<String, dynamic>)
          ? data
          : (data is Map)
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
      return NotificationPreferencesModel.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

