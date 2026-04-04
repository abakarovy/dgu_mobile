/// Временное состояние после мок-логина (до сохранения токена в [TokenStorage]).
/// Для [GET /auth/me] основной источник — заголовок `Authorization: Bearer mock_token_<id>`.
class MockSession {
  MockSession._();

  /// Последний успешный мок-логин (опционально, для отладки).
  static int? lastUserId;
}
