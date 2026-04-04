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
    final fromBody = fromResponseData(e.response?.data);
    if (fromBody != null && fromBody.trim().isNotEmpty) {
      return fromBody.trim();
    }

    // Нет тела ответа (таймаут, нет сети, отказ в соединении).
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Сервер не отвечает, попробуйте позже.';
      case DioExceptionType.connectionError:
        return 'Не удалось подключиться к серверу. Проверьте интернет и адрес API.';
      case DioExceptionType.badCertificate:
        return 'Ошибка защищённого соединения (сертификат).';
      case DioExceptionType.cancel:
        return 'Запрос отменён.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }
    return null;
  }
}
