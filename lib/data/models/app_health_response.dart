import '../../core/utils/app_semver.dart';

/// Ответ `GET /api/health` и блок проверки обновления приложения.
class AppHealthResponse {
  AppHealthResponse({
    required this.status,
    this.appUpdate,
    this.serverTime,
  });

  final String status;
  final AppUpdateInfo? appUpdate;
  final String? serverTime;

  factory AppHealthResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['app_update'] ?? json['appUpdate'];
    return AppHealthResponse(
      status: (json['status'] ?? 'ok').toString(),
      serverTime: json['server_time']?.toString() ?? json['serverTime']?.toString(),
      appUpdate: raw is Map
          ? AppUpdateInfo.fromJson(
              raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw),
            )
          : null,
    );
  }
}

/// Политика обновления с бэкенда (semver, см. MOBILE_HEALTH_CLIENT.md).
class AppUpdateInfo {
  AppUpdateInfo({
    required this.updateAvailable,
    required this.forceUpdate,
    this.latestVersion,
    this.minVersion,
    this.title,
    this.message,
    this.storeUrlAndroid,
    this.storeUrlIos,
    this.storeUrlRustore,
  });

  final bool updateAvailable;
  final bool forceUpdate;
  final String? latestVersion;
  final String? minVersion;
  final String? title;
  final String? message;
  final String? storeUrlAndroid;
  final String? storeUrlIos;
  final String? storeUrlRustore;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      updateAvailable: _bool(json['update_available'] ?? json['updateAvailable']),
      forceUpdate: _bool(json['force_update'] ?? json['forceUpdate']),
      latestVersion: json['latest_version']?.toString() ?? json['latestVersion']?.toString(),
      minVersion: json['min_version']?.toString() ?? json['minVersion']?.toString(),
      title: json['title']?.toString(),
      message: json['message']?.toString() ?? json['release_notes']?.toString(),
      storeUrlAndroid:
          json['store_url_android']?.toString() ?? json['storeUrlAndroid']?.toString(),
      storeUrlIos: json['store_url_ios']?.toString() ?? json['storeUrlIos']?.toString(),
      storeUrlRustore:
          json['store_url_rustore']?.toString() ?? json['storeUrlRustore']?.toString(),
    );
  }

  /// Нужно ли показывать диалог для [currentVersion] (semver без сборки).
  bool shouldPrompt(String currentVersion) {
    if (!updateAvailable) return false;
    if (isForcedFor(currentVersion)) return true;
    final latest = latestVersion?.trim();
    if (latest != null && latest.isNotEmpty && AppSemver.isGreaterOrEqual(currentVersion, latest)) {
      return false;
    }
    return true;
  }

  /// Блокирующее обновление: без «Позже», не уходить с bootstrap.
  bool isForcedFor(String currentVersion) {
    if (!updateAvailable) return false;
    if (forceUpdate) return true;
    final min = minVersion?.trim();
    if (min != null && min.isNotEmpty && AppSemver.isLessThan(currentVersion, min)) {
      return true;
    }
    return false;
  }

  static bool _bool(Object? v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
}
