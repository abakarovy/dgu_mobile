import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_log_file.dart';

/// Имя параметра в Firebase Remote Config (тип **Boolean**).
///
/// - `true` — приложение ходит в API как обычно.
/// - `false` — полноэкранное «приложение недоступно», все HTTP-запросы через [ApiClient] отклоняются.
///
/// В консоли Firebase: Remote Config → Add parameter → key `backend_access_enabled`, тип **Boolean**,
/// значение по умолчанию для всех пользователей.
///
/// Важно: если у условия стоит **Fetch % = 0%**, сервер **не отдаёт** это значение ни одному
/// приложению — остаётся старый шаблон (часто всё ещё `true`). Нужно **100%** или правка строки **Default value**.
const String kRemoteConfigBackendAccessEnabled = 'backend_access_enabled';

/// Состояние доступа к бэкенду из Remote Config.
class BackendAccessController extends ChangeNotifier {
  BackendAccessController._();
  static final BackendAccessController instance = BackendAccessController._();

  bool _remoteConfigReady = false;
  bool _backendBlocked = false;

  /// Remote Config успешно инициализирован и значение можно интерпретировать.
  bool get isRemoteConfigReady => _remoteConfigReady;

  /// Доступ к API закрыт по конфигу (`backend_access_enabled` == false).
  bool get isBackendBlocked => _remoteConfigReady && _backendBlocked;

  /// Для перехватчика Dio: блокировать только если RC реально дал запрет.
  bool get shouldBlockHttpRequests => isBackendBlocked;

  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      _remoteConfigReady = false;
      _backendBlocked = false;
      notifyListeners();
      return;
    }
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval:
            kReleaseMode ? const Duration(minutes: 15) : Duration.zero,
      ));
      await rc.setDefaults(const {kRemoteConfigBackendAccessEnabled: true});
      final activated = await rc.fetchAndActivate();
      _applyRemoteValues(rc);
      _remoteConfigReady = true;
      AppLogFile.writeln(
        '[RC] fetchAndActivate=$activated lastFetchStatus=${rc.lastFetchStatus} '
        'lastFetch=${rc.lastFetchTime} value=${rc.getValue(kRemoteConfigBackendAccessEnabled).asString()} '
        'backend_access_enabled(bool)=${rc.getBool(kRemoteConfigBackendAccessEnabled)} blocked=$_backendBlocked',
      );
    } catch (e, st) {
      AppLogFile.writeln('[RC] init failed (доступ к API не блокируем): $e');
      AppLogFile.writeln('$st');
      _remoteConfigReady = false;
      _backendBlocked = false;
    }
    notifyListeners();
  }

  /// Повторная загрузка конфига (кнопка «Обновить» или возврат приложения на передний план).
  Future<void> refresh() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      final activated = await rc.fetchAndActivate();
      _applyRemoteValues(rc);
      _remoteConfigReady = true;
      AppLogFile.writeln(
        '[RC] refresh fetchAndActivate=$activated lastFetchStatus=${rc.lastFetchStatus} '
        'value=${rc.getValue(kRemoteConfigBackendAccessEnabled).asString()} '
        'blocked=$_backendBlocked',
      );
    } catch (e) {
      AppLogFile.writeln('[RC] refresh failed: $e');
    }
    notifyListeners();
  }

  void _applyRemoteValues(FirebaseRemoteConfig rc) {
    final allowed = rc.getBool(kRemoteConfigBackendAccessEnabled);
    _backendBlocked = !allowed;
  }
}
