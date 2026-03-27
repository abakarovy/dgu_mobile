import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../data/api/api_client.dart';
import '../../data/api/auth_api.dart';
import '../../data/api/events_api.dart';
import '../../data/api/grades_api.dart';
import '../../data/api/groups_api.dart';
import '../../data/api/news_api.dart';
import '../../data/api/schedule_api.dart';
import '../../data/services/token_storage.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../core/cache/json_cache.dart';

/// Простой DI: инициализация один раз при старте, затем доступ к репозиториям.
abstract final class AppContainer {
  static AuthRepository? _authRepository;
  static AuthApi? _authApi;
  static NewsApi? _newsApi;
  static ScheduleApi? _scheduleApi;
  static EventsApi? _eventsApi;
  static GradesApi? _gradesApi;
  static GroupsApi? _groupsApi;
  static JsonCache? _jsonCache;

  static Future<void> init() async {
    final tokenStorage = await TokenStorage.create();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    _authApi = AuthApi(apiClient: apiClient, tokenStorage: tokenStorage);
    _authRepository = AuthRepositoryImpl(authApi: _authApi!, tokenStorage: tokenStorage);
    _newsApi = NewsApi(apiClient: apiClient);
    _scheduleApi = ScheduleApi(apiClient: apiClient);
    _eventsApi = EventsApi(apiClient: apiClient);
    _gradesApi = GradesApi(apiClient: apiClient);
    _groupsApi = GroupsApi(apiClient: apiClient);
    _jsonCache = await JsonCache.create();
  }

  static AuthRepository get authRepository {
    final r = _authRepository;
    if (r == null) throw StateError('AppContainer.init() must be called before using authRepository');
    return r;
  }

  static NewsApi get newsApi {
    final a = _newsApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using newsApi');
    return a;
  }

  static ScheduleApi get scheduleApi {
    final a = _scheduleApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using scheduleApi');
    return a;
  }

  static EventsApi get eventsApi {
    final a = _eventsApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using eventsApi');
    return a;
  }

  static GradesApi get gradesApi {
    final a = _gradesApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using gradesApi');
    return a;
  }

  static GroupsApi get groupsApi {
    final a = _groupsApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using groupsApi');
    return a;
  }

  static AuthApi get authApi {
    final a = _authApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using authApi');
    return a;
  }

  static JsonCache get jsonCache {
    final c = _jsonCache;
    if (c == null) throw StateError('AppContainer.init() must be called before using jsonCache');
    return c;
  }

  /// Прогреть кэш для экранов, чтобы не было спиннеров при навигации.
  static Future<void> prefetchAll() async {
    // Логика: каждый запрос сам пишет в кэш через контейнер/страницы.
    // Здесь централизуем и пишем в те же ключи, что читает UI.
    await Future.wait<void>([
      _prefetchMe(),
      _prefetchGroup(),
      _prefetchGrades(),
      _prefetchNews(),
      _prefetchEvents(),
      _prefetchScheduleWeek(),
      _prefetchScheduleToday(),
    ]);
  }

  static Future<void> _prefetchMe() async {
    try {
      final me = await authApi.getMe();
      await jsonCache.setJson('auth:me', me.toJson());
    } catch (_) {}
  }

  static Future<void> _prefetchGroup() async {
    try {
      final g = await groupsApi.getMyGroup();
      if (g != null) await jsonCache.setJson('groups:my', g.toJson());
    } catch (_) {}
  }

  static Future<void> _prefetchGrades() async {
    try {
      final fresh = await gradesApi.getMyGrades();
      final hasCached = jsonCache.getJsonList('grades:my') != null;
      // Не перетираем рабочий кэш пустым ответом.
      if (fresh.isNotEmpty || !hasCached) {
        await jsonCache.setJson(
          'grades:my',
          [
            for (final g in fresh)
              {
                'subject_name': g.subjectName,
                'grade': g.grade,
                'grade_type': g.gradeType,
                'teacher_name': g.teacherName,
                'date': g.date?.toIso8601String(),
              }
          ],
        );
      }
    } catch (_) {}
  }

  static Future<void> _prefetchNews() async {
    try {
      final fresh = await newsApi.getNews(limit: 30);
      final hasCached = jsonCache.getJsonList('news:list') != null;
      if (fresh.isNotEmpty || !hasCached) {
        await jsonCache.setJson('news:list', [for (final n in fresh) n.toJson()]);
      }
    } catch (_) {}
  }

  static Future<void> _prefetchEvents() async {
    try {
      final fresh = await eventsApi.getEvents();
      final hasCached = jsonCache.getJsonList('events:list') != null;
      if (fresh.isNotEmpty || !hasCached) {
        await jsonCache.setJson('events:list', [for (final e in fresh) e.toJson()]);
      }
    } catch (_) {}
  }

  static Future<void> _prefetchScheduleWeek() async {
    try {
      final fresh = await scheduleApi.getWeek();
      await jsonCache.setJson(
        'schedule:week',
        [
          for (final l in fresh)
            {
              'weekday_index': l.weekdayIndex,
              'subject': l.subject,
              'time': l.time,
              'teacher': l.teacher,
              'auditorium': l.auditorium,
            }
        ],
      );
    } catch (_) {}
  }

  static Future<void> _prefetchScheduleToday() async {
    try {
      final fresh = await scheduleApi.getToday();
      await jsonCache.setJson(
        'schedule:today',
        [
          for (final l in fresh)
            {
              'weekday_index': l.weekdayIndex,
              'subject': l.subject,
              'time': l.time,
              'teacher': l.teacher,
              'auditorium': l.auditorium,
            }
        ],
      );
    } catch (_) {}
  }
}
