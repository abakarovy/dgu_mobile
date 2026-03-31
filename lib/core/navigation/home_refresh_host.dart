/// Позволяет «Главной» реагировать на переход на вкладку.
///
/// Регистрируется в `HomePage` при монтировании, вызывается из `AppShellPage`
/// при нажатии на кнопку «Главная».
abstract final class HomeRefreshHost {
  static void Function({required bool force})? _onRequest;

  static void register(void Function({required bool force}) onRequest) {
    _onRequest = onRequest;
  }

  static void clear() {
    _onRequest = null;
  }

  static void requestRefresh({bool force = false}) {
    _onRequest?.call(force: force);
  }
}

