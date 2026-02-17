/// Исключения слоя данных (API, локальное хранилище).
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Ошибка сервера']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Нет соединения']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Ошибка кэша']);
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Требуется авторизация']);
}
