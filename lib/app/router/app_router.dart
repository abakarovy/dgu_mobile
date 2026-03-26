import 'package:go_router/go_router.dart';

import '../../features/events/presentation/pages/events_page.dart';
import '../../features/events/data/event_item.dart';
import '../../features/events/presentation/pages/event_detail_page.dart';
import '../../features/grades/presentation/pages/grades_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/login_email_page.dart';
import '../../features/news/data/news_item.dart';
import '../../features/news/presentation/pages/news_detail_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/profile/presentation/pages/student_id_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';

/// Конфигурация маршрутизации приложения.
/// StatefulShellRoute.indexedStack устраняет дублирование GlobalKey при переключении вкладок.
final GoRouter appRouter = GoRouter(
  initialLocation: '/app/home',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
      routes: [
        GoRoute(
          path: 'email',
          name: 'loginEmail',
          builder: (context, state) => const LoginEmailPage(),
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
              builder: (context, state) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'notifications',
                  name: 'notifications',
                  builder: (context, state) => const NotificationsPage(),
                ),
                GoRoute(
                  path: 'support',
                  name: 'support',
                  builder: (context, state) => const SupportPage(),
                ),
                GoRoute(
                  path: 'student-id',
                  name: 'studentId',
                  builder: (context, state) => const StudentIdPage(),
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
              builder: (context, state) => const GradesPage(),
            ),
          ],
        ),
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
              path: '/app/news',
              name: 'news',
              builder: (context, state) => const NewsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/app/events',
              name: 'events',
              builder: (context, state) => const EventsPage(),
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
    GoRoute(
      path: '/app/tasks',
      name: 'tasks',
      builder: (context, state) => const TasksPage(),
    ),
    GoRoute(
      path: '/app/news/detail',
      name: 'newsDetail',
      builder: (context, state) {
        final item = state.extra as NewsItem?;
        if (item == null) return const NewsPage();
        return NewsDetailPage(item: item);
      },
    ),
    GoRoute(
      path: '/app/events/detail',
      name: 'eventDetail',
      builder: (context, state) {
        final item = state.extra as EventItem?;
        if (item == null) return const EventsPage();
        return EventDetailPage(item: item);
      },
    ),
  ],
  // Backend/auth отключены: всегда пускаем в /app/*
  redirect: (context, state) async {
    final path = state.uri.path;

    // Нормализуем /app → /app/home
    if (path == '/app' || path == '/app/') return '/app/home';

    return null;
  },
);
