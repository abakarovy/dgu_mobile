import 'dart:convert';

import '../../data/models/user_model.dart';
import '../../data/services/token_storage.dart';
import 'demo_persona.dart';

/// Демо-аккаунт для проверки App Store / офлайн-демо без бэкенда.
abstract final class DemoSession {
  static const demoToken = 'mock-demo-session-dgu';

  static const email = DemoPersona.email;
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
        id: DemoPersona.userId,
        email: DemoPersona.email,
        fullName: DemoPersona.fullName,
        role: 'student',
        studentBookNumber: DemoPersona.studentBookNumber,
        course: DemoPersona.course,
        direction: DemoPersona.direction,
        department: DemoPersona.department,
        isActive: true,
        createdAt: DemoPersona.createdAt,
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
