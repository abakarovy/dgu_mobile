import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../services/token_storage.dart';

/// HTTP-клиент для College DGU API: base URL, Bearer-токен, логирование.
class ApiClient {
  ApiClient({required TokenStorage tokenStorage}) : _tokenStorage = tokenStorage {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) => handler.next(error),
    ));
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;
}
