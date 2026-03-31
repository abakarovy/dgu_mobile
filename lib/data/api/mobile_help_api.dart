import 'package:dio/dio.dart';

import '../models/help_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

class MobileHelpApi {
  MobileHelpApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// GET /api/mobile/help
  Future<HelpModel> getHelp() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/mobile/help',
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
      return HelpModel.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

