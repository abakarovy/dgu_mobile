import 'dart:async';

/// Глобальный обработчик "сессия истекла" (HTTP 401).
///
/// Используется из сетевого слоя (Dio) без зависимостей от UI.
/// UI/DI-слой регистрирует коллбек, который чистит сессию и навигирует на логин.
abstract final class UnauthorizedHandler {
  static Future<void> Function()? _onUnauthorized;
  static Future<void>? _inFlight;

  static void register(Future<void> Function() onUnauthorized) {
    _onUnauthorized = onUnauthorized;
  }

  static void clear() {
    _onUnauthorized = null;
  }

  static void notifyUnauthorized() {
    final cb = _onUnauthorized;
    if (cb == null) return;
    _inFlight ??= () async {
      try {
        await cb();
      } finally {
        _inFlight = null;
      }
    }();
  }
}

