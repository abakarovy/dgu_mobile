import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/bootstrap_page.dart';
import '../../core/auth/auth_session.dart';
import '../../core/di/app_container.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/events/data/event_item.dart';
import '../../features/events/presentation/pages/event_detail_page.dart';
import '../../features/grades/presentation/pages/grades_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/login_email_page.dart';
import '../../features/auth/presentation/pages/login_role_page.dart';
import '../../data/models/news_model.dart';
import '../../features/news/presentation/pages/news_detail_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/student_id_page.dart';
import '../../features/profile/presentation/pages/absences_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';
import '../../features/account/presentation/pages/email_change_page.dart';
import '../../features/account/presentation/pages/password_reset_page.dart';

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

/// Конфигурация маршрутизации приложения.
/// StatefulShellRoute.indexedStack устраняет дублирование GlobalKey при переключении вкладок.
final GoRouter appRouter = GoRouter(
  initialLocation: '/bootstrap',
  routes: [
    GoRoute(
      path: '/bootstrap',
      name: 'bootstrap',
      builder: (context, state) => const BootstrapPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginRolePage(),
      routes: [
        GoRoute(
          path: 'student',
          name: 'loginStudent',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: 'email',
          name: 'loginEmail',
          builder: (context, state) => LoginEmailPage(extra: state.extra),
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
                return GradesPage(
                  key: ValueKey('grades-${AuthSession.epoch}-${state.uri}'),
                  initialTabIndex: tab,
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

    // Не логин: запрещаем любые /app/*
    if (!isLoggedIn && path.startsWith('/app')) return '/login';

    // Уже залогинен: не показываем /login
    if (isLoggedIn && path.startsWith('/login')) return '/bootstrap';

    return null;
  },
);
