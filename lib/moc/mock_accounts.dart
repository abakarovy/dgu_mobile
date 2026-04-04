import 'dart:convert';

abstract final class MockAccounts {
  static const int ivanId = 1001;
  static const int mariaId = 1002;

  static const String ivanEmail = 'test1@test.ru';
  static const String ivanPassword = 'Test1234';

  static const String mariaEmail = 'test2@test.ru';
  static const String mariaPassword = 'Test1234';

  static Map<String, dynamic> userJsonById(int id) {
    if (id == ivanId) return _ivanUser;
    if (id == mariaId) return _mariaUser;
    return _ivanUser;
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

  static int variantIndexForUserId(int id) => id == mariaId ? 1 : 0;

  static MockLoginResult? tryLogin(String username, String password) {
    final u = username.trim().toLowerCase();
    final p = password;
    if (u == ivanEmail.toLowerCase() && p == ivanPassword) {
      return MockLoginResult(userJson: _ivanUser, userId: ivanId);
    }
    if (u == mariaEmail.toLowerCase() && p == mariaPassword) {
      return MockLoginResult(userJson: _mariaUser, userId: mariaId);
    }
    return null;
  }

  static String bearerForUserId(int id) => 'Bearer mock_token_$id';

  static String xUserDataHeaderFor(int id) {
    final json = jsonEncode(userJsonById(id));
    return base64Encode(utf8.encode(json));
  }

  static final Map<String, dynamic> _ivanUser = {
    'id': ivanId,
    'email': ivanEmail,
    'full_name': 'Петров Иван Сергеевич',
    'role': 'student',
    'student_book_number': 'УБ123456',
    'parent_email': 'parent.ivan@example.com',
    'course': 3,
    'direction': 'Информационные системы',
    'group_id': 501,
    'department': 'Информационные технологии',
    'bio': null,
    'is_active': true,
    'created_at': '2024-09-01T10:00:00Z',
  };

  static final Map<String, dynamic> _mariaUser = {
    'id': mariaId,
    'email': mariaEmail,
    'full_name': 'Сидорова Мария Александровна',
    'role': 'student',
    'student_book_number': 'УБ654321',
    'parent_email': null,
    'course': 2,
    'direction': 'Программирование',
    'group_id': 502,
    'department': 'Информационные технологии',
    'bio': null,
    'is_active': true,
    'created_at': '2024-09-01T10:00:00Z',
  };
}

class MockLoginResult {
  const MockLoginResult({required this.userJson, required this.userId});
  final Map<String, dynamic> userJson;
  final int userId;
}
