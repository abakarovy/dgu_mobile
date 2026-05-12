import 'dart:io';

import 'package:dgu_mobile/core/cache/json_cache.dart';

/// Локальный кэш `GET /api/1c/student-photo`.
///
/// - **Студент:** запрос с `?book=<зачётка>` (зачётка из `auth:me` / `1c:my-profile`), файл на диске:
///   `avatar_1c_u<userId>_b<book>.jpg` (аналог ключа «URL + user id»).
/// - **Родитель:** как раньше `?student_id=<ребёнок>`, файл: `avatar_1c_u<parentUserId>_s<childId>.jpg`.
abstract final class Profile1cPhotoCache {
  static int? _parseId(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static int? currentUserId(JsonCache cache) {
    return _parseId(cache.getJsonMap('auth:me')?['id']);
  }

  /// ID ребёнка для роли `parent` (`student_id` в query фото).
  static int? childStudentIdForParent(JsonCache cache) {
    final me = cache.getJsonMap('auth:me');
    if (me == null) return null;
    final role = (me['role'] ?? '').toString().trim().toLowerCase();
    if (role != 'parent') return null;
    final sd = cache.getJsonMap('parents:student-data');
    final st = sd?['student'];
    if (st is Map) {
      final id = _parseId(st['id']);
      if (id != null) return id;
    }
    return null;
  }

  /// Номер зачётной книжки для `?book=` (после логина — из `/auth/me`, иначе из кэша `1c:my-profile`).
  static String? studentBookForPhotoFromCache(JsonCache cache) {
    final me = cache.getJsonMap('auth:me');
    if (me != null) {
      final role = (me['role'] ?? '').toString().trim().toLowerCase();
      if (role == 'parent') return null;
      for (final key in ['student_book_number', 'studentBookNumber']) {
        final v = me[key];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    final p = cache.getJsonMap('1c:my-profile');
    if (p != null) {
      for (final key in ['student_book_number', 'studentBookNumber']) {
        final v = p[key];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  static bool isParentRole(JsonCache cache) {
    final me = cache.getJsonMap('auth:me');
    return (me?['role'] ?? '').toString().trim().toLowerCase() == 'parent';
  }

  /// Имя файла кэша или `null`, если контекст ещё не позволяет однозначно привязать фото.
  static String? diskCacheFileName(JsonCache cache) {
    final me = cache.getJsonMap('auth:me');
    if (me == null) return null;
    final uid = _parseId(me['id']);
    if (uid == null) return null;

    if (isParentRole(cache)) {
      final cid = childStudentIdForParent(cache);
      if (cid == null) return null;
      return 'avatar_1c_u${uid}_s$cid.jpg';
    }

    final book = studentBookForPhotoFromCache(cache);
    if (book == null || book.isEmpty) return null;
    final safeBook = book.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '_');
    return 'avatar_1c_u${uid}_b$safeBook.jpg';
  }

  static String absolutePathForFileName(String documentsDir, String fileName) =>
      '$documentsDir/$fileName';

  /// Синхронно: путь к уже скачанному файлу для текущего кэш-ключа, иначе `null`.
  static String? existingFilePathSync({
    required String? documentsDir,
    required JsonCache jsonCache,
  }) {
    if (documentsDir == null || documentsDir.trim().isEmpty) return null;
    final name = diskCacheFileName(jsonCache);
    if (name == null) return null;
    final path = absolutePathForFileName(documentsDir, name);
    try {
      final f = File(path);
      if (!f.existsSync()) return null;
      if (f.lengthSync() <= 0) return null;
      return path;
    } catch (_) {
      return null;
    }
  }
}
