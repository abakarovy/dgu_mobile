import '../entities/user_entity.dart';

/// Репозиторий аутентификации: вход, выход, текущий пользователь.
abstract class AuthRepository {
  /// Вход по email или номеру зачётки и паролю. Сохраняет токен и пользователя.
  Future<UserEntity> login({required String username, required String password});

  /// Проверка студента в 1С (по ФИО и № зачётки) перед регистрацией.
  Future<String?> verifyStudentIn1c({required String fullName, required String studentBookNumber});

  /// Регистрация студента (создаёт аккаунт и сразу авторизует по токену из заголовков).
  Future<UserEntity> registerStudent({
    required String fullName,
    required String studentBookNumber,
    required String email,
    required String password,
    String? registrationToken,
  });

  /// Выход: удаление токена и данных пользователя.
  Future<void> logout();

  /// Есть ли сохранённый токен.
  Future<bool> isLoggedIn();

  /// Текущий пользователь из кэша или /auth/me. null если не авторизован.
  Future<UserEntity?> getCurrentUser();
}
