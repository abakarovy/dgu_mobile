import 'package:shared_preferences/shared_preferences.dart';

import 'mock_mode.dart';
import 'mock_session.dart';

const _kMockStudentParentInvitePending = 'mock:student_parent_invite_pending';

/// Сохраняет состояние «приглашение родителю» для мока: после перезапуска
/// [MockSession.studentParentInvitePending] иначе сбрасывается.
abstract final class MockParentInvitePersistence {
  static Future<void> hydrateSession() async {
    if (!useMockBackend) return;
    final p = await SharedPreferences.getInstance();
    MockSession.studentParentInvitePending = p.getBool(_kMockStudentParentInvitePending) ?? false;
  }

  static Future<void> markInviteSent() async {
    if (!useMockBackend) return;
    MockSession.studentParentInvitePending = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMockStudentParentInvitePending, true);
  }

  /// Выход из аккаунта и сброс мок-данных.
  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kMockStudentParentInvitePending);
    if (useMockBackend) {
      MockSession.studentParentInvitePending = false;
    }
  }
}
