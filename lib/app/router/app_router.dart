import 'package:go_router/go_router.dart';

import '../../features/grades/presentation/pages/grades_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/shell/presentation/pages/app_shell_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

/// Конфигурация маршрутизации приложения.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShellPage(child: child),
      routes: [
        GoRoute(
          path: '/app/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/app/grades',
          name: 'grades',
          builder: (context, state) => const GradesPage(),
        ),
        GoRoute(
          path: '/app/news',
          name: 'news',
          builder: (context, state) => const NewsPage(),
        ),
        GoRoute(
          path: '/app/profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
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
