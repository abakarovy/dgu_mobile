import '../../core/constants/api_constants.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../data/api/api_client.dart';
import '../../data/api/auth_api.dart';
import '../../data/api/api_exception.dart';
import '../../data/api/account_api.dart';
import '../../data/api/assignments_api.dart';
import '../../data/api/events_api.dart';
import '../../data/api/grades_api.dart';
import '../../data/api/groups_api.dart';
import '../../data/api/mobile_help_api.dart';
import '../../data/api/news_api.dart';
import '../../data/api/notification_preferences_api.dart';
import '../../data/api/profile_1c_api.dart';
import '../../data/api/push_api.dart';
import '../../data/api/schedule_api.dart';
import '../../data/api/student_ticket_api.dart';
import '../../data/services/token_storage.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/schedule/domain/schedule_calendar_filter.dart';
import '../auth/auth_session.dart';
import '../../core/cache/json_cache.dart';

/// Простой DI: инициализация один раз при старте, затем доступ к репозиториям.
abstract final class AppContainer {
  static AuthRepository? _authRepository;
  static AuthApi? _authApi;
  static TokenStorage? _tokenStorage;
  static NewsApi? _newsApi;
  static ScheduleApi? _scheduleApi;
  static Profile1cApi? _profile1cApi;
  static EventsApi? _eventsApi;
  static GradesApi? _gradesApi;
  static GroupsApi? _groupsApi;
  static MobileHelpApi? _mobileHelpApi;
  static NotificationPreferencesApi? _notificationPreferencesApi;
  static AssignmentsApi? _assignmentsApi;
  static PushApi? _pushApi;
  static AccountApi? _accountApi;
  static StudentTicketApi? _studentTicketApi;
  static JsonCache? _jsonCache;

  static Future<void> init() async {
    final tokenStorage = await TokenStorage.create();
    final jsonCache = await JsonCache.create();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    _tokenStorage = tokenStorage;
    _authApi = AuthApi(apiClient: apiClient, tokenStorage: tokenStorage);
    _authRepository = AuthRepositoryImpl(
      authApi: _authApi!,
      tokenStorage: tokenStorage,
      jsonCache: jsonCache,
    );
    _newsApi = NewsApi(apiClient: apiClient);
    _scheduleApi = ScheduleApi(apiClient: apiClient);
    _profile1cApi = Profile1cApi(apiClient: apiClient);
    _eventsApi = EventsApi(apiClient: apiClient);
    _gradesApi = GradesApi(apiClient: apiClient);
    _groupsApi = GroupsApi(apiClient: apiClient);
    _mobileHelpApi = MobileHelpApi(apiClient: apiClient);
    _notificationPreferencesApi = NotificationPreferencesApi(apiClient: apiClient);
    _assignmentsApi = AssignmentsApi(apiClient: apiClient);
    _pushApi = PushApi(apiClient: apiClient);
    _accountApi = AccountApi(apiClient: apiClient);
    _studentTicketApi = StudentTicketApi(apiClient: apiClient);
    _jsonCache = jsonCache;
  }

  static AuthRepository get authRepository {
    final r = _authRepository;
    if (r == null) throw StateError('AppContainer.init() must be called before using authRepository');
    return r;
  }

  static TokenStorage get tokenStorage {
    final t = _tokenStorage;
    if (t == null) throw StateError('AppContainer.init() must be called before using tokenStorage');
    return t;
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

  static Profile1cApi get profile1cApi {
    final a = _profile1cApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using profile1cApi');
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

  static MobileHelpApi get mobileHelpApi {
    final a = _mobileHelpApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using mobileHelpApi');
    return a;
  }

  static NotificationPreferencesApi get notificationPreferencesApi {
    final a = _notificationPreferencesApi;
    if (a == null) {
      throw StateError('AppContainer.init() must be called before using notificationPreferencesApi');
    }
    return a;
  }

  static AssignmentsApi get assignmentsApi {
    final a = _assignmentsApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using assignmentsApi');
    return a;
  }

  static PushApi get pushApi {
    final a = _pushApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using pushApi');
    return a;
  }

  static AccountApi get accountApi {
    final a = _accountApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using accountApi');
    return a;
  }

  static StudentTicketApi get studentTicketApi {
    final a = _studentTicketApi;
    if (a == null) throw StateError('AppContainer.init() must be called before using studentTicketApi');
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

  /// Локально "выкинуть" пользователя без сетевых запросов (для 401/истёкшей сессии).
  static Future<void> forceLogoutLocal() async {
    try {
      await tokenStorage.clear();
    } catch (_) {}
    try {
      await jsonCache.clearAll();
    } catch (_) {}
    AuthSession.bump();
  }

  /// Прогреть кэш под splash. Каждый запрос не дольше [ApiConstants.prefetchRequestTimeout];
  /// при таймауте/ошибке остаётся старый кэш. Возвращает `true`, если все запросы успели успешно.
  static Future<bool> prefetchAll() async {
    final t = ApiConstants.prefetchRequestTimeout;

    // ВАЖНО: сначала подтверждаем сессию через /auth/me.
    // Если здесь 401 — не запускаем остальные prefetch, чтобы не спамить бэк и логи.
    final meOk = await _timedPrefetch(t, _prefetchMe);
    if (!meOk) return false;

    final results = await Future.wait<bool>([
      _timedPrefetch(t, _prefetchGroup),
      _timedPrefetch(t, _prefetchGrades),
      _timedPrefetch(t, _prefetchNews),
      _timedPrefetch(t, _prefetchEvents),
      _timedPrefetch(t, _prefetchHelp),
      _timedPrefetch(t, _prefetchNotificationPreferences),
      _timedPrefetch(t, _prefetchAssignments),
      _timedPrefetch(t, _prefetchStudentTicket),
      _timedPrefetch(ApiConstants.scheduleReceiveTimeout, _prefetchOneCProfile),
      _timedPrefetch(ApiConstants.prefetchScheduleTimeout, _prefetchScheduleCaches),
    ]);
    return results.every((ok) => ok);
  }

  static Future<bool> _timedPrefetch(
    Duration timeout,
    Future<void> Function() run,
  ) async {
    try {
      await run().timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _prefetchMe() async {
    final me = await authApi.getMe();
    await jsonCache.setJson('auth:me', me.toJson());
  }

  /// Нет группы у студента — не считаем ошибкой прогрева.
  static Future<void> _prefetchGroup() async {
    try {
      final g = await groupsApi.getMyGroup();
      if (g != null) await jsonCache.setJson('groups:my', g.toJson());
    } catch (e) {
      final c = (e is ApiException) ? e.statusCode : null;
      if (c == 404 || c == 403) return;
      rethrow;
    }
  }

  static Future<void> _prefetchGrades() async {
    final fresh = await gradesApi.getMyGrades();
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
            'semester': g.semester,
          }
      ],
    );
  }

  static Future<void> _prefetchNews() async {
    final fresh = await newsApi.getNews(limit: 30);
    await jsonCache.setJson('news:list', [for (final n in fresh) n.toJson()]);
  }

  static Future<void> _prefetchEvents() async {
    final fresh = await eventsApi.getEvents();
    await jsonCache.setJson('events:list', [for (final e in fresh) e.toJson()]);
  }

  static Future<void> _prefetchHelp() async {
    final h = await mobileHelpApi.getHelp();
    await jsonCache.setJson('mobile:help', {
      'hotline_phone': h.hotlinePhone,
      'email': h.email,
      'website_url': h.websiteUrl,
      'faq': [
        for (final f in (h.faq ?? const []))
          {'title': f.title, 'answer': f.answer}
      ],
    });
  }

  static Future<void> _prefetchNotificationPreferences() async {
    final p = await notificationPreferencesApi.getMy();
    await jsonCache.setJson('mobile:notification-preferences', p.toPatchJson());
  }

  static Future<void> _prefetchAssignments() async {
    final items = await assignmentsApi.getMy(limit: 50);
    await jsonCache.setJson('mobile:assignments:my', [
      for (final a in items)
        {
          'id': a.id,
          'title': a.title,
          'description': a.description,
          'subject': a.subject,
          'deadline_at': a.deadlineAt?.toIso8601String(),
          'created_at': a.createdAt?.toIso8601String(),
          'is_done': a.isDone,
        }
    ]);
  }

  static Future<void> _prefetchStudentTicket() async {
    final t = await studentTicketApi.getMyTicket();
    await jsonCache.setJson('mobile:student-ticket', t.toJsonMap());
  }

  static Future<void> _prefetchOneCProfile() async {
    final p = await profile1cApi.getMyProfile();
    await jsonCache.setJson('1c:my-profile', p.toJsonMap());
  }

  /// Неделя (7 запросов по дням) + срез «сегодня» для главной.
  static Future<void> _prefetchScheduleCaches() async {
    final week = await scheduleApi.getWeekForCalendar(DateTime.now());
    await jsonCache.setJson(
      'schedule:week:v2',
      [for (final l in week) l.toJsonMap()],
    );
    final today = filterScheduleForCalendarToday(week);
    await jsonCache.setJson(
      'schedule:today',
      [for (final l in today) l.toJsonMap()],
    );
  }
}
