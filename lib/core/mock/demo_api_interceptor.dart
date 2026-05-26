import 'package:dio/dio.dart';

import 'demo_mock_responses.dart';
import 'demo_session.dart';

/// Подменяет ответы API для демо-сессии ([DemoSession.demoToken]).
class DemoApiInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!DemoSession.isActive) {
      return handler.next(options);
    }

    final mock = DemoMockResponses.tryResolve(options);
    if (mock == null) {
      return handler.next(options);
    }

    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: mock.statusCode,
        data: mock.data,
        headers: mock.headers,
      ),
    );
  }
}

class DemoMockPayload {
  const DemoMockPayload({
    required this.statusCode,
    required this.data,
    this.headers,
  });

  final int statusCode;
  final dynamic data;
  final Headers? headers;
}
