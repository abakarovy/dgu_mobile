import 'package:dio/dio.dart';

import 'api_error_parser.dart';

/// Исключение API, предназначенное для показа пользователю (текст берём из бэка).
class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  static ApiException fromDio(DioException e) {
    final msg = ApiErrorParser.fromDioException(e) ?? '';
    final m = msg.trim().isEmpty ? 'Ошибка' : msg.trim();
    return ApiException(m, e.response?.statusCode);
  }
}

