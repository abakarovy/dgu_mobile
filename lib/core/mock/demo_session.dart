import 'dart:convert';

import '../../data/models/user_model.dart';
import '../../data/services/token_storage.dart';

/// Демо-аккаунт для проверки App Store / офлайн-демо без бэкенда.
abstract final class DemoSession {
  static const demoToken = 'mock-demo-session-dgu';

  static const email = 'test@test.ru';
  static const password = 'test1234';

  static bool _active = false;

  static bool get isActive => _active;

  static bool credentialsMatch(String username, String password) {
    return username.trim().toLowerCase() == email && password == DemoSession.password;
  }

  static bool isDemoToken(String? token) =>
      token != null && token.isNotEmpty && token == demoToken;

  static void markActive() => _active = true;

  static void markInactive() => _active = false;

  static UserModel get demoUser => const UserModel(
        id: 900001,
        email: email,
        fullName: 'Тестов Тест Тестович',
        role: 'student',
        studentBookNumber: '12345',
        course: 2,
        direction: '09.02.07 Информатика и вычислительная техника',
        groupId: 101,
        department: 'Отделение информационных технологий',
        isActive: true,
        createdAt: '2024-09-01T00:00:00Z',
      );

  static Future<void> activate(TokenStorage tokenStorage) async {
    final user = demoUser;
    await tokenStorage.setToken(demoToken);
    await tokenStorage.setUserDataJson(jsonEncode(user.toJson()));
    markActive();
  }

  static Future<void> deactivate(TokenStorage tokenStorage) async {
    markInactive();
    await tokenStorage.clear();
  }

  /// После [AppContainer.init]: восстановить флаг, если в хранилище демо-токен.
  static Future<void> restoreFromStorage(TokenStorage tokenStorage) async {
    final token = await tokenStorage.getToken();
    if (isDemoToken(token)) {
      markActive();
    } else {
      markInactive();
    }
  }
}
