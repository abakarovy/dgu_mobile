/// Базовый класс ошибок доменного слоя (для use cases).
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Ошибка сервера']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Нет соединения']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Ошибка авторизации']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Ошибка кэша']);
}
