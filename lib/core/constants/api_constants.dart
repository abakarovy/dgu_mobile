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
  /// Запросы к API: Wi‑Fi / первый коннект к бэку на телефоне часто > 5 с — иначе ложные таймауты.
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// `/1c/schedule` у 1С часто отвечает дольше 5 с; отдельный лимит на приём тела ответа.
  static const Duration scheduleReceiveTimeout = Duration(seconds: 90);

  /// Тот же лимит для параллельного прогрева кэша на splash.
  static const Duration prefetchRequestTimeout = Duration(seconds: 15);

  /// Прогрев недели — до 7 последовательных запросов расписания.
  static const Duration prefetchScheduleTimeout = Duration(seconds: 120);

  static const String authLoginPath = '/auth/login';
  static const String authMePath = '/auth/me';

  /// Профиль студента из 1С (HTTP-сервис зачётки + оценки).
  /// Руководство backend: `GET /api/1c/my-profile?mobile=true`.
  static const String oneCMyProfilePath = '/1c/my-profile';

  /// Оценки из 1С: `GET /api/1c/sync-grades?student_id=…`
  static const String oneCSyncGradesPath = '/1c/sync-grades';

  /// Итоговые оценки: `GET /api/1c/final-grades?student_id=…`
  static const String oneCFinalGradesPath = '/1c/final-grades';

  /// Пропуски: `GET /api/1c/absences?student_id=&start=&end=`
  static const String oneCAbsencesPath = '/1c/absences';

  /// Учебный план: `GET /api/1c/curriculum?student_id=`
  static const String oneCCurriculumPath = '/1c/curriculum';

  /// Состав группы: `GET /api/1c/group-list?student_id=`
  static const String oneCGroupListPath = '/1c/group-list';

  /// Курсовые, ВКР, практики: `GET /api/1c/practices?student_id=`
  static const String oneCPracticesPath = '/1c/practices';

  /// Заказы справок: `GET /api/1c/orders?student_id=`
  static const String oneCOrdersPath = '/1c/orders';

  /// Кураторские часы в 1С (не путать с `GET /api/mobile/events`).
  static const String oneCCuratorEventsPath = '/1c/events';

  /// `GET /api/health`
  static const String healthPath = '/health';
}
