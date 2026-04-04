import 'package:dio/dio.dart';

import '../models/event_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

class EventsApi {
  EventsApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// `GET /api/mobile/events?skip=&limit=&upcoming_only=`
  ///
  /// По умолчанию [upcomingOnly] = `false`, чтобы в ленту попадали и прошедшие
  /// мероприятия (архив). Для только предстоящих — `upcomingOnly: true`.
  /// [limit] не больше 100 (ограничение backend).
  Future<List<EventModel>> getEvents({
    int skip = 0,
    int limit = 30,
    bool upcomingOnly = false,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    try {
      final res = await _api.dio.get<dynamic>(
        '/mobile/events',
        queryParameters: {
          'skip': skip,
          'limit': safeLimit,
          'upcoming_only': upcomingOnly,
        },
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

  /// Опубликованная карточка: `GET /api/mobile/events/{id}` (иначе 404).
  Future<EventModel?> getPublishedEvent(int eventId) async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/mobile/events/$eventId',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200 || res.data == null) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
      final raw = res.data;
      if (raw is! Map) return null;
      return EventModel.fromJson(Map<String, dynamic>.from(raw));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

