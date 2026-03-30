import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../di/app_container.dart';

/// Режим красной полосы над AppBar: нет сети или бэкенд не ответил вовремя.
enum AppNetworkBannerKind {
  none,
  offline,
  serverStale,
}

/// Глобальное состояние деградации сети / API и кнопка «Обновить».
final class AppNetworkBannerController extends ChangeNotifier {
  AppNetworkBannerController._();
  static final AppNetworkBannerController instance = AppNetworkBannerController._();

  AppNetworkBannerKind _kind = AppNetworkBannerKind.none;
  bool _refreshBusy = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  AppNetworkBannerKind get kind => _kind;
  bool get refreshBusy => _refreshBusy;

  static bool isOfflineResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.length == 1 && results.single == ConnectivityResult.none;
  }

  static Future<bool> checkDeviceOffline() async {
    try {
      final r = await Connectivity().checkConnectivity();
      return isOfflineResult(r);
    } on MissingPluginException {
      // Плагин не зарегистрирован (hot reload после добавления пакета и т.п.) — считаем «сеть есть».
      return false;
    } catch (_) {
      return false;
    }
  }

  void applyAfterBootstrap({required bool deviceOffline, required bool allPrefetchOk}) {
    if (deviceOffline) {
      _setKind(AppNetworkBannerKind.offline);
    } else if (!allPrefetchOk) {
      _setKind(AppNetworkBannerKind.serverStale);
    } else {
      _setKind(AppNetworkBannerKind.none);
    }
  }

  void _setKind(AppNetworkBannerKind k) {
    if (_kind == k) return;
    _kind = k;
    notifyListeners();
  }

  void startConnectivityListener() {
    if (_connectivitySub != null) return;
    try {
      _connectivitySub = Connectivity().onConnectivityChanged.listen(
        (results) {
          if (isOfflineResult(results)) {
            _setKind(AppNetworkBannerKind.offline);
          } else {
            if (_kind == AppNetworkBannerKind.offline) {
              unawaited(refreshAfterConnectivityRestored());
            }
          }
        },
        onError: (Object _, StackTrace _) {
          _connectivitySub?.cancel();
          _connectivitySub = null;
        },
        cancelOnError: true,
      );
    } on MissingPluginException {
      _connectivitySub = null;
    } catch (_) {
      _connectivitySub = null;
    }
  }

  Future<void> refreshAfterConnectivityRestored() async {
    final offline = await checkDeviceOffline();
    if (offline) return;
    final ok = await AppContainer.prefetchAll();
    _setKind(ok ? AppNetworkBannerKind.none : AppNetworkBannerKind.serverStale);
  }

  Future<void> refresh() async {
    if (_refreshBusy) return;
    _refreshBusy = true;
    notifyListeners();
    try {
      final offline = await checkDeviceOffline();
      if (offline) {
        _setKind(AppNetworkBannerKind.offline);
        return;
      }
      final ok = await AppContainer.prefetchAll();
      _setKind(ok ? AppNetworkBannerKind.none : AppNetworkBannerKind.serverStale);
    } finally {
      _refreshBusy = false;
      notifyListeners();
    }
  }

  void disposeController() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
