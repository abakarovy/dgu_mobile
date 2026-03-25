/// Позволяет открыть режим настройки нижней панели из любого экрана (например, «Профиль»).
/// Регистрируется в [AppShellPage] при монтировании.
abstract final class NavBarEditHost {
  static void Function()? _onRequest;

  static void register(void Function() onRequest) {
    _onRequest = onRequest;
  }

  /// Снимает обработчик (вызывать из [dispose] оболочки).
  static void clear() {
    _onRequest = null;
  }

  static void requestEditMode() {
    _onRequest?.call();
  }
}
