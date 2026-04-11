import 'dart:convert';

import 'mock_data_loader.dart';

abstract final class MockAccounts {
  static int get aliId => MockDataLoader.accounts['aliId'] as int;

  static int get parentId => MockDataLoader.accounts['parentId'] as int;

  /// Id зачётной книжки из 1С в профиле совпадает с мок-студентом [aliId].
  static const int mockStudentBookNumberAsLegacyId = 23385;

  /// Любой неизвестный id (старый токен, номер зачётки вместо user id) → студент мока.
  static int canonicalUserIdForMock(int id) {
    if (id == mockStudentBookNumberAsLegacyId) return aliId;
    final users = MockDataLoader.accounts['users'] as Map<String, dynamic>;
    if (users.containsKey('$id')) return id;
    return aliId;
  }

  static Map<String, dynamic> userJsonById(int id) {
    final cid = canonicalUserIdForMock(id);
    final users = MockDataLoader.accounts['users'] as Map<String, dynamic>;
    final raw = users['$cid'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    final fallback = users['$aliId'];
    if (fallback is Map) {
      return Map<String, dynamic>.from(fallback);
    }
    throw StateError('MockAccounts: нет пользователя $id и нет fallback aliId=$aliId');
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
    final logins = MockDataLoader.accounts['logins'] as Map<String, dynamic>;
    final st = logins['student'] as Map<String, dynamic>;
    final pa = logins['parent'] as Map<String, dynamic>;
    if (u == (st['email'] as String).trim().toLowerCase() && p == st['password']) {
      return MockLoginResult(userJson: userJsonById(aliId), userId: aliId);
    }
    if (u == (pa['email'] as String).trim().toLowerCase() && p == pa['password']) {
      return MockLoginResult(userJson: userJsonById(parentId), userId: parentId);
    }
    return null;
  }

  static String bearerForUserId(int id) => 'Bearer mock_token_$id';

  static String xUserDataHeaderFor(int id) {
    final json = jsonEncode(userJsonById(id));
    return base64Encode(utf8.encode(json));
  }
}

class MockLoginResult {
  const MockLoginResult({required this.userJson, required this.userId});
  final Map<String, dynamic> userJson;
  final int userId;
}
