import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../core/di/app_container.dart';
import '../../data/models/news_model.dart';
import '../../firebase_options.dart';

/// Обработчик сообщений FCM в изолятe; обязателен для корректного приёма в фоне (Android).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Открытие экранов по `data` из push (напр. `type=news`, `id=<число>`).
class PushNavigation {
  PushNavigation._();

  static RemoteMessage? _pendingTerminatedLaunch;

  static void holdTerminatedLaunchMessage(RemoteMessage? message) {
    _pendingTerminatedLaunch = message;
  }

  /// Вызывать после входа в приложение (например с [BootstrapPage]), когда уже есть контекст навигации.
  static Future<void> consumePendingIfAny() async {
    final msg = _pendingTerminatedLaunch;
    _pendingTerminatedLaunch = null;
    if (msg == null) return;
    await handleRemoteMessage(msg);
  }

  static Future<void> onNotificationOpened(RemoteMessage message) =>
      handleRemoteMessage(message);

  static Future<void> handleRemoteMessage(RemoteMessage message) async {
    final ctx = appRootNavigatorKey.currentContext;
    if (ctx == null) return;

    final data = message.data;
    final type = data['type']?.toString().toLowerCase().trim();

    if (type == 'news') {
      final idRaw = data['id']?.toString();
      final id = int.tryParse(idRaw ?? '');
      if (id != null) await _openNews(ctx, id);
      return;
    }

    if (type == 'grades' ||
        type == 'grade' ||
        type == 'new_grade' ||
        type == 'new_grades' ||
        type == 'push_new_grades') {
      await _openGradesFromPush(ctx, data);
      return;
    }
  }

  /// Дата оценки в `data`: `date` или `graded_at`, формат `YYYY-MM-DD` или ISO 8601.
  static DateTime? parseGradeFocusDate(Map<String, dynamic> data) {
    final raw = (data['date'] ?? data['graded_at'])?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    final p = DateTime.tryParse(raw);
    if (p != null) return DateTime(p.year, p.month, p.day);
    final m = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(raw);
    if (m != null) {
      final dd = int.tryParse(m.group(1)!);
      final mm = int.tryParse(m.group(2)!);
      final yy = int.tryParse(m.group(3)!);
      if (dd != null && mm != null && yy != null) return DateTime(yy, mm, dd);
    }
    return null;
  }

  static Future<void> _openGradesFromPush(BuildContext context, Map<String, dynamic> data) async {
    final focus = parseGradeFocusDate(data);
    final qp = <String, String>{'tab': '0'};
    if (focus != null) {
      qp['focusDate'] =
          '${focus.year}-${focus.month.toString().padLeft(2, '0')}-${focus.day.toString().padLeft(2, '0')}';
    }
    final path = Uri(path: '/app/grades', queryParameters: qp).toString();
    if (context.mounted) GoRouter.of(context).go(path);
  }

  static Future<void> _openNews(BuildContext context, int id) async {
    try {
      final cached = AppContainer.jsonCache.getJsonList('news:list');
      if (cached != null) {
        for (final item in cached) {
          if (item is Map && _idOf(item) == id) {
            final m = NewsModel.fromJson(Map<String, dynamic>.from(item));
            if (context.mounted) {
              GoRouter.of(context).push('/app/news/detail', extra: m);
            }
            return;
          }
        }
      }
    } catch (_) {}

    try {
      final fresh = await AppContainer.newsApi.getNewsById(id);
      if (!context.mounted) return;
      if (fresh != null) {
        GoRouter.of(context).push('/app/news/detail', extra: fresh);
      } else {
        GoRouter.of(context).go('/app/news');
      }
    } catch (_) {
      if (context.mounted) GoRouter.of(context).go('/app/news');
    }
  }

  static int _idOf(Map<dynamic, dynamic> raw) {
    final v = raw['id'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
