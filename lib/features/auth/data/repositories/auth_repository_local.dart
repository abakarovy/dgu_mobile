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
  Future<UserEntity> login({required String username, required String password}) async {
    return _mockUser;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<UserEntity?> getCurrentUser() async => _mockUser;
}
