import 'package:dio/dio.dart';

import '../models/group_model.dart';
import 'api_client.dart';

class GroupsApi {
  GroupsApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// GET /api/groups/my
  Future<GroupModel?> getMyGroup() async {
    final res = await _api.dio.get<dynamic>(
      '/groups/my',
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    if (res.statusCode != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'Не удалось загрузить группу',
      );
    }

    final data = res.data;
    if (data is Map<String, dynamic>) {
      // может быть { ...group fields... } или { "group": {..} }
      final inner = (data['group'] is Map) ? Map<String, dynamic>.from(data['group'] as Map) : data;
      return GroupModel.fromJson(inner);
    }
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map) return GroupModel.fromJson(Map<String, dynamic>.from(first));
    }
    return null;
  }
}

