import 'package:go_router/go_router.dart';

import '../../features/grades/presentation/pages/grades_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

/// Конфигурация маршрутизации приложения.
/// StatefulShellRoute.indexedStack устраняет дублирование GlobalKey при переключении вкладок.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShellPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/grades',
              name: 'grades',
              builder: (context, state) => const GradesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/news',
              name: 'news',
              builder: (context, state) => const NewsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'notifications',
                  name: 'notifications',
                  builder: (context, state) => const NotificationsPage(),
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
      builder: (context, state) => const SchedulePage(),
    ),
  ],
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == '/app' || path == '/app/') return '/app/home';
    return null;
  },
);
