import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold, Center, Text, GlobalKey, NavigatorState;

import 'package:go_router/go_router.dart';

import '../bootstrap/bootstrap_page.dart';
import '../../data/api/edu_disclosure_api.dart';
import '../../core/auth/auth_session.dart';
import '../../core/di/app_container.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/events/data/event_item.dart';
import '../../features/events/presentation/pages/event_detail_page.dart';
import '../../features/grades/presentation/pages/grades_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/svedeniya/svedeniya_pages.dart';
import '../../features/applicant/presentation/pages/applicant_home_page.dart';
import '../../features/public/presentation/pages/public_shell_page.dart';
import '../../features/public/presentation/pages/public_profile_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/login_email_page.dart';
import '../../data/models/news_model.dart';
import '../../features/news/presentation/pages/news_detail_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/student_id_page.dart';
import '../../features/profile/presentation/pages/wifi_password_request_page.dart';
import '../../features/profile/presentation/pages/absences_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';
import '../../features/account/presentation/pages/email_change_page.dart';
import '../../features/account/presentation/pages/password_reset_page.dart';
import '../../features/profile/presentation/pages/certificate_order_page.dart';
import '../../features/student/presentation/pages/student_hub_page.dart';
import '../../features/student/presentation/pages/lms_page.dart';
import '../../features/student/presentation/pages/department_announcements_page.dart';
import '../../features/student/presentation/pages/portfolio_page.dart';
import '../../features/student/presentation/pages/scholarship_rating_page.dart';
import '../../features/student/presentation/pages/scholarship_section_page.dart';
import '../../features/student/presentation/pages/student_portal_page.dart';

/// Полноэкранные подмаршруты с кнопкой «назад»: [CupertinoPage] даёт свайп с края (iOS).
Page<void> _cupertinoSubpage({
  required LocalKey key,
  required String? name,
  required Widget child,
}) {
  return CupertinoPage<void>(
    key: key,
    name: name,
    child: child,
  );
}

/// Ключ корневого навигатора: push-навигация и [GoRouter] после cold start.
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appRoot');

/// Конфигурация маршрутизации приложения.
/// StatefulShellRoute.indexedStack устраняет дублирование GlobalKey при переключении вкладок.
Map<String, dynamic> _svedeniyaExtraMap(Object? extra) {
  if (extra is Map<String, dynamic>) return extra;
  if (extra is Map) return Map<String, dynamic>.from(extra);
  return AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey) ?? const {};
}

final GoRouter appRouter = GoRouter(
  navigatorKey: appRootNavigatorKey,
  initialLocation: '/bootstrap',
  routes: [
    GoRoute(
      path: '/bootstrap',
      name: 'bootstrap',
      builder: (context, state) => const BootstrapPage(),
    ),
    GoRoute(
      path: '/applicant',
      redirect: (_, _) => '/public/home',
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          PublicShellPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/public/home',
              name: 'publicHome',
              builder: (context, state) => const PublicHomePage(),
              routes: [
                GoRoute(
                  path: 'svedeniya',
                  name: 'publicSvedeniya',
                  pageBuilder: (context, state) => _cupertinoSubpage(
                    key: state.pageKey,
                    name: state.name,
                    child: const SvedeniyaHubPage(),
                  ),
                  routes: [
                    GoRoute(
                      path: ':rootId',
                      name: 'publicSvedeniyaSection',
                      pageBuilder: (context, state) {
                        final extra = state.extra;
                        final data = _svedeniyaExtraMap(extra);
                        return _cupertinoSubpage(
                          key: state.pageKey,
                          name: state.name,
                          child: SvedeniyaSectionPage(
                            rootId: state.pathParameters['rootId'] ?? '',
                            disclosure: data,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/public/news',
              name: 'publicNews',
              builder: (context, state) => const NewsPage(
                newsDetailRoute: '/public/news/detail',
                eventsDetailRoute: '/public/news/events/detail',
                newsTabRoute: '/public/news',
              ),
              routes: [
                GoRoute(
                  path: 'detail',
                  name: 'publicNewsDetail',
                  pageBuilder: (context, state) {
                    final item = state.extra as NewsModel?;
                    return _cupertinoSubpage(
                      key: state.pageKey,
                      name: state.name,
                      child: item == null
                          ? const NewsPage()
                          : NewsDetailPage(item: item),
                    );
                  },
                ),
                GoRoute(
                  path: 'events/detail',
                  name: 'publicEventDetail',
                  pageBuilder: (context, state) {
                    final item = state.extra as EventItem?;
                    return _cupertinoSubpage(
                      key: state.pageKey,
                      name: state.name,
                      child: item == null
                          ? const NewsPage(initialTab: NewsTab.events)
                          : EventDetailPage(item: item),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/public/profile',
              name: 'publicProfile',
              builder: (context, state) => const PublicProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      redirect: (context, state) {
        if (state.uri.path == '/login' || state.uri.path == '/login/') {
          return '/public/profile';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: 'student',
          name: 'loginStudent',
          pageBuilder: (context, state) => _cupertinoSubpage(
            key: state.pageKey,
            name: state.name,
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: 'email',
          name: 'loginEmail',
          pageBuilder: (context, state) => _cupertinoSubpage(
            key: state.pageKey,
            name: state.name,
            child: LoginEmailPage(extra: state.extra),
          ),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShellPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/profile',
              name: 'profile',
              builder: (context, state) =>
                  ProfilePage(key: ValueKey(AuthSession.epoch)),
              routes: [
                GoRoute(
                  path: 'notifications',
                  name: 'notifications',
                  pageBuilder: (context, state) => _cupertinoSubpage(
                    key: state.pageKey,
                    name: state.name,
                    child: const NotificationsPage(),
                  ),
                ),
                GoRoute(
                  path: 'support',
                  name: 'support',
                  pageBuilder: (context, state) => _cupertinoSubpage(
                    key: state.pageKey,
                    name: state.name,
                    child: const SupportPage(),
                  ),
                ),
                GoRoute(
                  path: 'student-id',
                  name: 'studentId',
                  pageBuilder: (context, state) => _cupertinoSubpage(
                    key: state.pageKey,
                    name: state.name,
                    child: const StudentIdPage(),
                  ),
                ),
                GoRoute(
                  path: 'absences',
                  name: 'absences',
                  pageBuilder: (context, state) => _cupertinoSubpage(
                    key: state.pageKey,
                    name: state.name,
                    child: const AbsencesPage(),
                  ),
                ),
                GoRoute(
                  path: 'settings',
                  name: 'settings',
                  pageBuilder: (context, state) => _cupertinoSubpage(
                    key: state.pageKey,
                    name: state.name,
                    child: const SettingsPage(),
                  ),
                ),
                GoRoute(
                  path: 'wifi-password',
                  name: 'wifiPassword',
                  pageBuilder: (context, state) => _cupertinoSubpage(
                    key: state.pageKey,
                    name: state.name,
                    child: const WifiPasswordRequestPage(),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/grades',
              name: 'grades',
              builder: (context, state) {
                final tabParam = state.uri.queryParameters['tab'];
                final tab = int.tryParse(tabParam ?? '')?.clamp(0, 2) ?? 0;
                final focusRaw =
                    state.uri.queryParameters['focusDate'] ?? state.uri.queryParameters['date'];
                DateTime? focusDate;
                if (focusRaw != null && focusRaw.trim().isNotEmpty) {
                  final p = DateTime.tryParse(focusRaw.trim());
                  if (p != null) {
                    focusDate = DateTime(p.year, p.month, p.day);
                  }
                }
                return GradesPage(
                  key: ValueKey('grades-${AuthSession.epoch}-${state.uri}'),
                  initialTabIndex: tab,
                  focusGradeDate: focusDate,
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/home',
              name: 'home',
              builder: (context, state) =>
                  HomePage(key: ValueKey(AuthSession.epoch)),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/news',
              name: 'news',
              builder: (context, state) =>
                  NewsPage(key: ValueKey(AuthSession.epoch)),
              routes: [
                GoRoute(
                  path: 'events',
                  name: 'eventsInNews',
                  builder: (context, state) =>
                      NewsPage(
                        key: ValueKey(AuthSession.epoch),
                        initialTab: NewsTab.events,
                      ),
                ),
                GoRoute(
                  path: 'events/detail',
                  name: 'eventDetailInNews',
                  pageBuilder: (context, state) {
                    final item = state.extra as EventItem?;
                    return _cupertinoSubpage(
                      key: state.pageKey,
                      name: state.name,
                      child: item == null
                          ? const EventsPage()
                          : EventDetailPage(item: item),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/app/schedule',
      name: 'schedule',
      pageBuilder: (context, state) => _cupertinoSubpage(
        key: state.pageKey,
        name: state.name,
        child: SchedulePage(key: ValueKey(AuthSession.epoch)),
      ),
    ),
    // Аккаунт: отдельные полноэкранные страницы БЕЗ нижнего меню.
    GoRoute(
      path: '/account/email-change',
      name: 'accountEmailChange',
      pageBuilder: (context, state) => _cupertinoSubpage(
        key: state.pageKey,
        name: state.name,
        child: const EmailChangePage(),
      ),
    ),
    GoRoute(
      path: '/account/password-reset',
      name: 'accountPasswordReset',
      pageBuilder: (context, state) => _cupertinoSubpage(
        key: state.pageKey,
        name: state.name,
        child: const PasswordResetPage(),
      ),
    ),
    GoRoute(
      path: '/account/certificate-order',
      name: 'accountCertificateOrder',
      pageBuilder: (context, state) => _cupertinoSubpage(
        key: state.pageKey,
        name: state.name,
        child: const CertificateOrderPage(),
      ),
    ),
        GoRoute(
          path: '/app/student',
          name: 'studentHub',
          pageBuilder: (context, state) => _cupertinoSubpage(
            key: ValueKey<String>('studentHub|${state.uri}'),
            name: state.name,
            child: const StudentHubPage(),
          ),
      routes: [
        GoRoute(
          path: 'lms',
          name: 'studentLms',
          pageBuilder: (c, s) => _cupertinoSubpage(
            key: ValueKey<String>('studentLms|${s.uri}'),
            name: s.name,
            child: const LmsCredentialsPage(),
          ),
        ),
        GoRoute(
          path: 'announcements',
          name: 'studentAnnouncements',
          pageBuilder: (c, s) => _cupertinoSubpage(
            key: ValueKey<String>('studentAnnouncements|${s.uri}'),
            name: s.name,
            child: const DepartmentAnnouncementsPage(),
          ),
        ),
        GoRoute(
          path: 'portfolio',
          name: 'studentPortfolio',
          pageBuilder: (c, s) => _cupertinoSubpage(
            key: ValueKey<String>('studentPortfolio|${s.uri}'),
            name: s.name,
            child: const PortfolioPage(),
          ),
        ),
        GoRoute(
          path: 'scholarship',
          name: 'studentScholarship',
          pageBuilder: (c, s) => _cupertinoSubpage(
            key: ValueKey<String>('studentScholarship|${s.uri}'),
            name: s.name,
            child: const ScholarshipRatingPage(),
          ),
          routes: [
            GoRoute(
              path: 'section',
              name: 'studentScholarshipSection',
              pageBuilder: (c, s) {
                final extra = s.extra;
                final child = extra is ScholarshipSectionExtra
                    ? ScholarshipSectionPage(extra: extra)
                    : const Scaffold(body: Center(child: Text('Нет данных раздела')));
                // `s.pageKey` для этого маршрута одинаков при любом `extra` — при втором push в стеке
                // Navigator получает дублирующийся ключ. Ключ включает раздел/год/семестр.
                final LocalKey pageKey = extra is ScholarshipSectionExtra
                    ? ValueKey<String>(
                        'studentScholarshipSection|${extra.sectionRef}|${extra.academicYear}|${extra.semester}|${identityHashCode(extra.navigationToken)}',
                      )
                    : ValueKey<String>('studentScholarshipSection|fallback|${identityHashCode(s)}');
                return _cupertinoSubpage(
                  key: pageKey,
                  name: s.name,
                  child: child,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'portal',
          name: 'studentPortal',
          pageBuilder: (c, s) => _cupertinoSubpage(
            key: ValueKey<String>('studentPortal|${s.uri}'),
            name: s.name,
            child: const StudentPortalPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/app/tasks',
      name: 'tasks',
      pageBuilder: (context, state) => _cupertinoSubpage(
        key: state.pageKey,
        name: state.name,
        child: const TasksPage(),
      ),
    ),
    GoRoute(
      path: '/app/news/detail',
      name: 'newsDetail',
      pageBuilder: (context, state) {
        final item = state.extra as NewsModel?;
        return _cupertinoSubpage(
          key: state.pageKey,
          name: state.name,
          child: item == null
              ? const NewsPage()
              : NewsDetailPage(item: item),
        );
      },
    ),
  ],
  redirect: (context, state) async {
    final path = state.uri.path;

    if (path == '/bootstrap') return null;

    // Нормализуем /app → /app/home
    if (path == '/app' || path == '/app/') return '/app/home';

    final isLoggedIn = await AppContainer.authRepository.isLoggedIn();

    // Гость: только публичный режим
    if (!isLoggedIn && path.startsWith('/app')) return '/public/home';
    if (!isLoggedIn && (path == '/login' || path == '/login/')) return '/public/profile';

    // Старые маршруты абитуриента → главная гостя
    if (path == '/applicant' ||
        path.startsWith('/applicant/') ||
        path.startsWith('/login/applicant')) {
      return '/public/home';
    }

    if (path == '/public' || path == '/public/') return '/public/home';

    // Залогинен: не показываем гостевой shell и экран выбора роли
    if (isLoggedIn && path.startsWith('/public')) return '/bootstrap';
    if (isLoggedIn && path.startsWith('/login')) return '/bootstrap';

    return null;
  },
);
