import '../entities/user_entity.dart';

/// Репозиторий аутентификации: вход, выход, текущий пользователь.
abstract class AuthRepository {
  /// Вход по email или номеру зачётки и паролю. Сохраняет токен и пользователя.
  Future<UserEntity> login({required String username, required String password});

  /// Выход: удаление токена и данных пользователя.
  Future<void> logout();

  /// Есть ли сохранённый токен.
  Future<bool> isLoggedIn();

  /// Текущий пользователь из кэша или /auth/me. null если не авторизован.
  Future<UserEntity?> getCurrentUser();
}
