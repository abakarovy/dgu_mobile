import 'package:dio/dio.dart';

/// Единый парсер ошибок бэка.
///
/// Поддерживает:
/// - { success:false, error:{code,message,fields?}, detail }
/// - старый FastAPI 422: { detail: [{msg: "..."}] }
abstract final class ApiErrorParser {
  static String? fromResponseData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map) {
        final m = err['message'];
        if (m is String && m.trim().isNotEmpty) return m.trim();
        final fields = err['fields'];
        if (fields is List && fields.isNotEmpty) {
          final first = fields.first;
          if (first is Map && first['message'] is String) {
            final s = (first['message'] as String).trim();
            if (s.isNotEmpty) return s;
          }
        }
      }
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          final s = (first['msg'] as String).trim();
          if (s.isNotEmpty) return s;
        }
      }
    }
    return null;
  }

  static String? fromDioException(DioException e) {
    return fromResponseData(e.response?.data);
  }
}

