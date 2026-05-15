import '../auth_flow_results.dart';
import '../entities/user_entity.dart';

/// Репозиторий аутентификации: вход, выход, текущий пользователь.
abstract class AuthRepository {
  /// Вход по email или номеру зачётки и паролю. При OTP — второй вызов с [otpCode].
  Future<AuthLoginResult> login({
    required String username,
    required String password,
    String? otpCode,
  });

  /// Проверка студента в 1С (по ФИО и № зачётки) перед регистрацией.
  /// [lastName], [firstName], [patronymic] — для отчёта в поддержку при ошибках.
  Future<String?> verifyStudentIn1c({
    required String fullName,
    required String studentBookNumber,
    String? lastName,
    String? firstName,
    String? patronymic,
  });

  /// POST `/auth/student/support/registration-report` (без JWT) — по кнопке «Отправить в поддержку».
  /// При **404** бэкенд уже ставит письмо в YouGile; повторный вызов — по желанию пользователя.
  Future<String> submitRegistrationSupportReport({
    required String source,
    required String message,
    required String fullName,
    required String studentBookNumber,
    String? lastName,
    String? firstName,
    String? patronymic,
    String? registrationEmail,
    String? errorCode,
  });

  /// Регистрация студента; при OTP — повтор с [otpCode].
  Future<AuthRegisterResult> registerStudent({
    required String fullName,
    required String studentBookNumber,
    required String email,
    required String password,
    String? registrationToken,
    String? otpCode,
  });

  /// Выход: удаление токена и данных пользователя.
  Future<void> logout();

  /// Есть ли сохранённый токен.
  Future<bool> isLoggedIn();

  /// Текущий пользователь из кэша или /auth/me. null если не авторизован.
  Future<UserEntity?> getCurrentUser();
}
