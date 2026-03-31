import 'package:dio/dio.dart';

import '../models/assignment_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AssignmentsApi {
  AssignmentsApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// GET /api/mobile/assignments/my
  Future<List<AssignmentModel>> getMy({int skip = 0, int limit = 50}) async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/mobile/assignments/my',
        queryParameters: {'skip': skip, 'limit': limit},
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
      final list = (data is List)
          ? data
          : (data is Map<String, dynamic> && data['items'] is List)
              ? (data['items'] as List)
              : (data is Map<String, dynamic> && data['assignments'] is List)
                  ? (data['assignments'] as List)
                  : <dynamic>[];

      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(AssignmentModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/mobile/assignments (teacher/admin)
  Future<AssignmentModel> create(AssignmentCreate body) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/mobile/assignments',
        data: body.toJson(),
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
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
      final inner = (map['item'] is Map) ? Map<String, dynamic>.from(map['item'] as Map) : map;
      return AssignmentModel.fromJson(inner);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

