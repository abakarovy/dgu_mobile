import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/one_c_my_profile.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// `GET /api/1c/my-profile` — профиль студента из 1С.
class Profile1cApi {
  Profile1cApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<OneCMyProfile> getMyProfile() async {
    try {
      final res = await _api.dio.get<dynamic>(
        ApiConstants.oneCMyProfilePath,
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
