import '../di/app_container.dart';

/// Отображение ФИО ребёнка для роли `parent` (кэш `parents:student-data`, `auth:me`).
abstract final class ParentChildName {
  static Map<String, dynamic>? _me() => AppContainer.jsonCache.getJsonMap('auth:me');

  /// Текущий пользователь — родитель (по кэшу `/api/auth/me`).
  static bool isParentRole() {
    final m = _me();
    return (m?['role'] ?? '').toString().trim().toLowerCase() == 'parent';
  }

  /// `users.id` ребёнка из кэша `GET /api/parents/student-data`.
  static int? childStudentId() {
    final sd = AppContainer.jsonCache.getJsonMap('parents:student-data');
    if (sd == null) return null;
    final st = sd['student'];
    if (st is! Map) return null;
    final id = st['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return null;
  }

  /// Если кэш пуст (например вкладку открыли до prefetch), один раз подгружает `parents:student-data`.
  static Future<int?> ensureChildStudentIdLoaded() async {
    final existing = childStudentId();
    if (existing != null) return existing;
    if (!isParentRole()) return null;
    try {
      final data = await AppContainer.accountApi.getParentsStudentData();
      await AppContainer.jsonCache.setJson('parents:student-data', data);
      return childStudentId();
    } catch (_) {
      return null;
    }
  }

  /// Полное ФИО ребёнка в род. п. для «Родитель — …» (как в `full_name_genitive` с бэка).
  static String? childFullGenitiveLine() {
    if (!isParentRole()) return null;
    final sd = AppContainer.jsonCache.getJsonMap('parents:student-data');
    final student = sd?['student'];
    if (student is Map) {
      final m = Map<String, dynamic>.from(student);
      final gen = (m['full_name_genitive'] ?? '').toString().trim();
      if (gen.isNotEmpty) {
        final parts = gen.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
        return parts.map(_capWord).join(' ');
      }
    }
    return twoWordGenitiveLabel();
  }

  /// Два слова (фамилия + имя) в родительном падеже для UI: баннер без префикса «Родитель».
  static String? twoWordGenitiveLabel() {
    if (!isParentRole()) return null;
    final sd = AppContainer.jsonCache.getJsonMap('parents:student-data');
    final student = sd?['student'];
    if (student is Map) {
      final m = Map<String, dynamic>.from(student);
      final gen = (m['full_name_genitive'] ?? '').toString().trim();
      if (gen.isNotEmpty) {
        final parts = gen.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
        final raw = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : gen;
        return _formatTwoWordName(raw);
      }
      final fn = (m['full_name'] ?? '').toString().trim();
      if (fn.isNotEmpty) {
        return _formatTwoWordName(_toGenitiveFromFullName(fn));
      }
    }
    return null;
  }

  /// Строка «Родитель — Ягияева Али Тажутдиновича» (полное ФИО в род. п., если есть в API).
  static String? settingsRoditelChildLine() {
    final line = childFullGenitiveLine();
    if (line == null || line.trim().isEmpty) return null;
    return 'Родитель — $line';
  }

  static String _formatTwoWordName(String raw) {
    final parts = raw.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return raw.trim();
    if (parts.length >= 2) {
      return '${_capWord(parts[0])} ${_capWord(parts[1])}'.trim();
    }
    return _capWord(parts[0]);
  }

  static String _toGenitiveFromFullName(String fullName) {
    final s = fullName.trim();
    if (s.isEmpty) return '';
    final parts = s.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return s;
    final last = parts[0];
    final first = parts.length > 1 ? parts[1] : '';
    final lastGen = _lastNameToGenitive(last);
    return [lastGen, first].where((x) => x.trim().isNotEmpty).join(' ');
  }

  static String _lastNameToGenitive(String lastName) {
    final src = lastName.trim();
    if (src.isEmpty) return src;
    final lower = src.toLowerCase();
    String out;
    if (lower.endsWith('ев') || lower.endsWith('ёв')) {
      out = '${src.substring(0, src.length - 2)}ева';
    } else if (lower.endsWith('ов')) {
      out = '${src.substring(0, src.length - 2)}ова';
    } else if (lower.endsWith('ин')) {
      out = '${src.substring(0, src.length - 2)}ина';
    } else if (lower.endsWith('ий')) {
      out = '${src.substring(0, src.length - 2)}ия';
    } else if (lower.endsWith('ый') || lower.endsWith('ой')) {
      out = '${src.substring(0, src.length - 2)}ого';
    } else if (lower.endsWith('а')) {
      out = '${src.substring(0, src.length - 1)}ы';
    } else if (lower.endsWith('я')) {
      out = '${src.substring(0, src.length - 1)}и';
    } else {
      out = '$srcа';
    }
    final cap = _capWord(out);
    final isUpper = src == src.toUpperCase();
    return isUpper ? cap.toUpperCase() : cap;
  }

  static String _capWord(String w) {
    final t = w.trim();
    if (t.isEmpty) return t;
    final rest = t.length > 1 ? t.substring(1).toLowerCase() : '';
    return t[0].toUpperCase() + rest;
  }
}
