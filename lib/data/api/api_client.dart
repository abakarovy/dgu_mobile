import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

    // 1) Auth header
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

    // 2) Logging (all API calls)
    _dio.interceptors.add(_ApiLogInterceptor());
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;
}

class _ApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kReleaseMode) {
      final uri = options.uri;
      debugPrint('[API] → ${options.method} $uri');
      if (options.headers.isNotEmpty) {
        // Avoid logging huge headers; hide auth token.
        final safe = Map<String, dynamic>.from(options.headers);
        if (safe['Authorization'] != null) safe['Authorization'] = 'Bearer ***';
        debugPrint('[API]   headers: $safe');
      }
      if (options.data != null) {
        debugPrint('[API]   body: ${options.data}');
      }
    }
    options.extra['__t0_ms'] = DateTime.now().millisecondsSinceEpoch;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final t0 = response.requestOptions.extra['__t0_ms'];
    final dt = (t0 is int) ? (DateTime.now().millisecondsSinceEpoch - t0) : null;
    if (!kReleaseMode) {
      debugPrint('[API] ← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}'
          '${dt == null ? '' : ' (${dt}ms)'}');
      if (response.data != null) {
        debugPrint('[API]   data: ${response.data}');
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final ro = err.requestOptions;
    final t0 = ro.extra['__t0_ms'];
    final dt = (t0 is int) ? (DateTime.now().millisecondsSinceEpoch - t0) : null;
    if (!kReleaseMode) {
      debugPrint('[API] ← ERROR ${ro.method} ${ro.uri}${dt == null ? '' : ' (${dt}ms)'}');
      debugPrint('[API]   type: ${err.type} message: ${err.message}');
      if (err.response != null) {
        debugPrint('[API]   status: ${err.response?.statusCode}');
        debugPrint('[API]   data: ${err.response?.data}');
      }
    }
    super.onError(err, handler);
  }
}
