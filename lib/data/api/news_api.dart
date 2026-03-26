import 'package:dio/dio.dart';

import '../models/news_model.dart';
import 'api_client.dart';

class NewsApi {
  NewsApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<NewsModel>> getNews({int skip = 0, int limit = 20}) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/news',
      queryParameters: {'skip': skip, 'limit': limit},
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    if (res.statusCode != 200 || res.data == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'Не удалось загрузить новости',
      );
    }
    return res.data!
        .whereType<Map<String, dynamic>>()
        .map(NewsModel.fromJson)
        .toList();
  }
}

