import '../../domain/auth_flow_results.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Локальный заглушка AuthRepository — без обращения к бэку.
/// Для работы приложения офлайн / без сервера.
class AuthRepositoryLocal implements AuthRepository {
  static const _mockUser = UserEntity(
    id: 'local-1',
    email: 'student@local.dgu.ru',
    fullName: 'Студент (локально)',
    role: 'student',
    studentBookNumber: '000000',
    course: 1,
    direction: 'Информатика',
  );

  @override
  Future<AuthLoginResult> login({
    required String username,
    required String password,
    String? otpCode,
  }) async {
    return AuthLoginSuccess(_mockUser);
  }

  @override
  Future<String?> verifyStudentIn1c({
    required String fullName,
    required String studentBookNumber,
  }) async {
    // Локальный режим: считаем проверку успешной.
    return null;
  }

  @override
  Future<AuthRegisterResult> registerStudent({
    required String fullName,
    required String studentBookNumber,
    required String email,
    required String password,
    String? registrationToken,
    String? otpCode,
  }) async {
    return AuthRegisterSuccess(
      UserEntity(
        id: 'local-registered-1',
        email: email,
        fullName: fullName,
        role: 'student',
        studentBookNumber: studentBookNumber,
        course: 1,
        direction: 'Информатика',
      ),
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<UserEntity?> getCurrentUser() async => _mockUser;
}
