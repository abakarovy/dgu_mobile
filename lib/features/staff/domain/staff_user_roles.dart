/// Роли пользователей в админке (как на сайте).
abstract final class StaffUserRoles {
  static const allRoles = [
    ('student', 'Студент'),
    ('parent', 'Родитель'),
    ('teacher', 'Преподаватель'),
    ('department', 'Зав. отделением'),
    ('department_methodist', 'Методист отделения'),
    ('methodist', 'Методист'),
    ('event_manager', 'Менеджер мероприятий'),
    ('admin', 'Администратор'),
  ];

  static String labelFor(String? role) {
    final r = (role ?? '').trim().toLowerCase();
    for (final e in allRoles) {
      if (e.$1 == r) return e.$2;
    }
    if (r.isEmpty) return '—';
    return role!.trim();
  }

  static String? roleKeyForLabel(String label) {
    final t = label.trim();
    for (final e in allRoles) {
      if (e.$2 == t) return e.$1;
    }
    return null;
  }
}
