import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/auth/unauthorized_handler.dart';
import '../../core/logging/app_log_file.dart';
import '../../moc/mock_dio_interceptor.dart';
import '../../moc/mock_mode.dart';
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
      onError: (error, handler) {
        final code = error.response?.statusCode;
        if (code == 401) {
          UnauthorizedHandler.notifyUnauthorized();
        }
        return handler.next(error);
      },
    ));

    // 2) Логирование всех вызовов (в т.ч. мок) — до мока, иначе при `resolve` не было бы строки [API] →.
    _dio.interceptors.add(_ApiLogInterceptor());

    // 3) Локальные ответы без HTTP (после подстановки Bearer — см. [MockDioInterceptor]).
    if (useMockBackend) {
      _dio.interceptors.add(MockDioInterceptor());
    }
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;
}

class _ApiLogInterceptor extends Interceptor {
  void _log(String line) {
    if (!kReleaseMode) {
      debugPrint(line);
    }
    AppLogFile.writeln(line);
  }

  static String _summarizeData(dynamic data) {
    if (data == null) return 'null';
    // Binary payloads (e.g. student photo) may be `List<int>` and would spam logs.
    if (data is List<int>) return 'bytes(len=${data.length})';
    if (data is Uint8List) return 'bytes(len=${data.length})';
    if (data is List && data.isNotEmpty && data.first is int) return 'bytes(len=${data.length})';
    final s = data.toString();
    // Avoid huge payloads in logs.
    if (s.length > 2000) return '${s.substring(0, 2000)}…(truncated)';
    return s;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    _log('[API] → ${options.method} $uri');
    if (options.headers.isNotEmpty) {
      // Avoid logging huge headers; hide auth token.
      final safe = Map<String, dynamic>.from(options.headers);
      if (safe['Authorization'] != null) safe['Authorization'] = 'Bearer ***';
      _log('[API]   headers: $safe');
    }
    if (options.data != null) {
      _log('[API]   body: ${options.data}');
    }
    options.extra['__t0_ms'] = DateTime.now().millisecondsSinceEpoch;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final t0 = response.requestOptions.extra['__t0_ms'];
    final dt = (t0 is int) ? (DateTime.now().millisecondsSinceEpoch - t0) : null;
    _log('[API] ← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}'
        '${dt == null ? '' : ' (${dt}ms)'}');
    if (response.data != null) {
      _log('[API]   data: ${_summarizeData(response.data)}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final ro = err.requestOptions;
    final t0 = ro.extra['__t0_ms'];
    final dt = (t0 is int) ? (DateTime.now().millisecondsSinceEpoch - t0) : null;
    _log('[API] ← ERROR ${ro.method} ${ro.uri}${dt == null ? '' : ' (${dt}ms)'}');
    _log('[API]   type: ${err.type} message: ${err.message}');
    if (err.response != null) {
      _log('[API]   status: ${err.response?.statusCode}');
      _log('[API]   data: ${_summarizeData(err.response?.data)}');
    }
    super.onError(err, handler);
  }
}
