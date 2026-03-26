import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Константы API College DGU (base URL, таймауты).
/// Для Android-эмулятора используйте: http://10.0.2.2:8000/api
abstract final class ApiConstants {
  static String get baseUrl {
    // Priority:
    // 1) .env (flutter_dotenv)
    // 2) --dart-define=API_BASE_URL=...
    // 3) default (Android emulator → host)
    const fallback = 'http://10.0.2.2:8000/api';
    final v = dotenv.env['API_BASE_URL'];
    if (v != null && v.trim().isNotEmpty) return v.trim();
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return fromDefine.trim().isNotEmpty ? fromDefine.trim() : fallback;
  }
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String authLoginPath = '/auth/login';
  static const String authMePath = '/auth/me';
}
