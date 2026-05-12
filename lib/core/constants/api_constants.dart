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

  /// Учебный план (РУП): `GET /api/1c/curriculum` — см. MOBILE_STUDENT_MODULES_RU §1.3;
  /// на бэке часто передаётся `?student_id=`.
  static const String oneCCurriculumPath = '/1c/curriculum';

  /// Состав группы: `GET /api/1c/group-list?student_id=`
  static const String oneCGroupListPath = '/1c/group-list';

  /// Курсовые, ВКР, практики: `GET /api/1c/practices?student_id=`
  static const String oneCPracticesPath = '/1c/practices';

  /// Кураторские часы в 1С (не путать с `GET /api/mobile/events`).
  static const String oneCCuratorEventsPath = '/1c/events';

  /// Фото студента (бинарное): `GET /api/1c/student-photo?book=` (студент) или `?student_id=` (родитель).
  static const String oneCStudentPhotoPath = '/1c/student-photo';

  /// `GET /api/health`
  static const String healthPath = '/health';

  // --- Справки (документы), см. MOBILE_SPRAVKI_API.md ---

  /// `POST /api/documents/certificate-order`
  static const String documentsCertificateOrderPath = '/documents/certificate-order';

  /// `GET /api/documents/certificate-orders` — история заказов
  static const String documentsCertificateOrdersPath = '/documents/certificate-orders';

  /// Склеивает хост без суффикса `/api` с относительным `file_url` (`/uploads/...`).
  static String resolvePublicFileUrl(String fileUrl) {
    final u = fileUrl.trim();
    if (u.isEmpty) return u;
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final base = baseUrl.trim();
    final origin = base.replaceFirst(RegExp(r'/api/?$'), '');
    if (u.startsWith('/')) return '$origin$u';
    return '$origin/$u';
  }

  /// Внешний каталог LMS (Урайт и т.п.), если задаётся в `.env`.
  static String get externalLmsCatalogUrl {
    final v = dotenv.env['EXTERNAL_LMS_CATALOG_URL'];
    if (v != null && v.trim().isNotEmpty) return v.trim();
    const fromDefine = String.fromEnvironment('EXTERNAL_LMS_CATALOG_URL', defaultValue: '');
    return fromDefine.trim();
  }

  /// Базовый сайт для относительных ссылок портала «Студентам» (`/svedeniya/...`).
  /// По умолчанию — основной сайт ДГУ.
  static String get portalSiteOrigin {
    final v = dotenv.env['PORTAL_SITE_ORIGIN'];
    if (v != null && v.trim().isNotEmpty) return _trimTrailingSlash(v.trim());
    const fromDefine = String.fromEnvironment('PORTAL_SITE_ORIGIN', defaultValue: '');
    if (fromDefine.trim().isNotEmpty) return _trimTrailingSlash(fromDefine.trim());
    return 'https://dgu.ru';
  }

  static String _trimTrailingSlash(String s) => s.replaceAll(RegExp(r'/+$'), '');

  /// Разрешает `href` из API портала (относительный путь или полный URL).
  static String resolvePortalHref(String href) {
    final h = href.trim();
    if (h.isEmpty) return h;
    if (h.startsWith('http://') || h.startsWith('https://')) return h;
    final origin = portalSiteOrigin;
    if (h.startsWith('/')) return '$origin$h';
    return '$origin/$h';
  }
}
