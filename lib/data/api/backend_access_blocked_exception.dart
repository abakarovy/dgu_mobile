/// Запрос к API отменён: в Firebase Remote Config выключен доступ (`backend_access_enabled` = false).
class BackendAccessBlockedException implements Exception {
  const BackendAccessBlockedException();

  @override
  String toString() => 'BackendAccessBlockedException';
}
