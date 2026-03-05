/// Константы API College DGU (base URL, таймауты).
/// Для Android-эмулятора используйте: http://10.0.2.2:8000/api
abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String authLoginPath = '/auth/login';
  static const String authMePath = '/auth/me';
}
