import 'package:dio/dio.dart';

import '../models/news_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

class NewsApi {
  NewsApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<NewsModel>> getNews({int skip = 0, int limit = 20}) async {
    try {
      final res = await _api.dio.get<dynamic>(
        '/news',
        queryParameters: {'skip': skip, 'limit': limit},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200 || res.data == null) {
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
              : (data is Map<String, dynamic> && data['news'] is List)
                  ? (data['news'] as List)
                  : (data is Map<String, dynamic> && data['data'] is List)
                      ? (data['data'] as List)
                      : <dynamic>[];

      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(NewsModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

