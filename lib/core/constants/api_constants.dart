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
  /// Запросы к API: после этого времени клиент обрывает ожидание (кэш / деградация).
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 5);

  /// `/1c/schedule` у 1С часто отвечает дольше 5 с; отдельный лимит на приём тела ответа.
  static const Duration scheduleReceiveTimeout = Duration(seconds: 90);

  /// Тот же лимит для параллельного прогрева кэша на splash.
  static const Duration prefetchRequestTimeout = Duration(seconds: 5);

  /// Прогрев недели — до 7 последовательных запросов расписания.
  static const Duration prefetchScheduleTimeout = Duration(seconds: 120);

  static const String authLoginPath = '/auth/login';
  static const String authMePath = '/auth/me';

  /// Профиль студента из 1С (HTTP-сервис зачётки + оценки).
  static const String oneCMyProfilePath = '/1c/my-profile';
}
