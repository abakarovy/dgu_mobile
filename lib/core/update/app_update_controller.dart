import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/app_health_response.dart';
import '../device/app_runtime_info.dart';

/// Решение «показать обновление / заблокировать вход» после `/api/health`.
final class AppUpdateController {
  AppUpdateController._();

  static const String _dismissedVersionKey = 'app_update_dismissed_version';

  static AppUpdateInfo? pending;
  static bool shouldBlockNavigation = false;

  static bool get _isStorePlatform {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      _ => false,
    };
  }

  static Future<void> ingest(AppHealthResponse? health) async {
    pending = null;
    shouldBlockNavigation = false;

    if (!_isStorePlatform) return;

    final update = health?.appUpdate;
    if (update == null) return;

    await AppRuntimeInfo.instance.ensureLoaded();
    final currentVersion = AppRuntimeInfo.instance.version;
    if (!update.shouldPrompt(currentVersion)) return;

    if (!update.isForcedFor(currentVersion)) {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(_dismissedVersionKey)?.trim();
      final latest = update.latestVersion?.trim();
      if (dismissed != null &&
          dismissed.isNotEmpty &&
          latest != null &&
          latest.isNotEmpty &&
          dismissed == latest) {
        return;
      }
    }

    pending = update;
    shouldBlockNavigation = update.isForcedFor(currentVersion);
  }

  static Future<void> dismissOptional() async {
    final u = pending;
    if (u == null) return;
    await AppRuntimeInfo.instance.ensureLoaded();
    if (u.isForcedFor(AppRuntimeInfo.instance.version)) return;
    final latest = u.latestVersion?.trim();
    if (latest == null || latest.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, latest);
    pending = null;
  }

  static void clearPending() {
    pending = null;
    shouldBlockNavigation = false;
  }
}
