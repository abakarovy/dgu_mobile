import 'package:flutter/foundation.dart';

/// Вызывается из нижней навигации при переходе на вкладку «Новости» —
/// список обновляется из сети (как [HomeRefreshHost] для главной).
abstract final class NewsRefreshHost {
  static VoidCallback? _onRequest;

  static void register(VoidCallback onRequest) {
    _onRequest = onRequest;
  }

  static void clear() {
    _onRequest = null;
  }

  static void requestRefresh() {
    _onRequest?.call();
  }
}
