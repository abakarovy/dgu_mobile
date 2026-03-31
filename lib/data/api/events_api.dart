import 'package:dio/dio.dart';

import '../models/event_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

class EventsApi {
  EventsApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// GET /api/mobile/events
  Future<List<EventModel>> getEvents() async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/mobile/events',
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
          : (data is Map<String, dynamic> && data['events'] is List)
              ? (data['events'] as List)
              : (data is Map<String, dynamic> && data['items'] is List)
                  ? (data['items'] as List)
                  : <dynamic>[];

      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(EventModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

