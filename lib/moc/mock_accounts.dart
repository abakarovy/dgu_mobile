import 'dart:convert';

abstract final class MockAccounts {
  /// Единственный мок-пользователь: Али Ягияев (как в логах).
  static const int aliId = 28;

  /// Родитель, привязанный к тому же студенту [aliId] (мок).
  static const int parentId = 29;

  static const String aliEmail = 'ali.yagiyaev@yandex.ru';
  static const String aliPassword = 'Test1234';

  static const String parentEmail = 'parent.mock@example.com';
  static const String parentPassword = 'Test1234';

  static Map<String, dynamic> userJsonById(int id) {
    if (id == parentId) return _parentUser;
    return _aliUser;
  }

  /// `Bearer mock_token_<id>` → JSON пользователя для [GET /auth/me].
  static Map<String, dynamic>? userJsonFromBearer(String? authHeader) {
    if (authHeader == null || authHeader.isEmpty) return null;
    final m = RegExp(r'Bearer\s+mock_token_(\d+)', caseSensitive: false).firstMatch(authHeader);
    if (m == null) return null;
    final id = int.tryParse(m.group(1)!);
    if (id == null) return null;
    return userJsonById(id);
  }

  static MockLoginResult? tryLogin(String username, String password) {
    final u = username.trim().toLowerCase();
    final p = password;
    if (u == aliEmail.toLowerCase() && p == aliPassword) {
      return MockLoginResult(userJson: _aliUser, userId: aliId);
    }
    if (u == parentEmail.toLowerCase() && p == parentPassword) {
      return MockLoginResult(userJson: _parentUser, userId: parentId);
    }
    return null;
  }

  static String bearerForUserId(int id) => 'Bearer mock_token_$id';

  static String xUserDataHeaderFor(int id) {
    final json = jsonEncode(userJsonById(id));
    return base64Encode(utf8.encode(json));
  }

  static final Map<String, dynamic> _aliUser = {
    'id': aliId,
    'email': aliEmail,
    'full_name': 'ЯГИЯЕВ АЛИ ТАЖУТДИНОВИЧ',
    'role': 'student',
    'student_book_number': '23385',
    'parent_email': null,
    'course': 3,
    'direction': '10.02.05 Обеспечение информационной безопасности автоматизированных систем',
    'group_id': null,
    'department': 'Обеспечение информационной безопасности автоматизированных систем',
    'bio': null,
    'is_active': true,
    'force_password_change': false,
    'created_at': '2026-03-30T15:37:15.799890',
  };

  static final Map<String, dynamic> _parentUser = {
    'id': parentId,
    'email': parentEmail,
    'full_name': 'Родитель — Ягияев Али Тажутдинович',
    'role': 'parent',
    'student_book_number': null,
    'parent_email': null,
    'course': null,
    'direction': null,
    'group_id': null,
    'department': null,
    'bio': null,
    'is_active': true,
    'force_password_change': false,
    'created_at': '2026-03-30T15:37:21.003677',
  };
}

class MockLoginResult {
  const MockLoginResult({required this.userJson, required this.userId});
  final Map<String, dynamic> userJson;
  final int userId;
}
