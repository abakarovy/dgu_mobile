import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Отображение статуса пользователя (как в админке сайта).
class StaffUserStatusInfo {
  const StaffUserStatusInfo({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
}

abstract final class StaffUserStatus {
  /// Все статусы пользователя (тест + активен + смена пароля и т.д.).
  static List<StaffUserStatusInfo> allFromUser(Map<String, dynamic> user) {
    final result = <StaffUserStatusInfo>[];
    final seen = <String>{};

    void add(StaffUserStatusInfo info) {
      if (seen.add(info.label)) result.add(info);
    }

    if (user['is_test_user'] == true) add(_test);
    if (user['force_password_change'] == true) add(_forcePasswordChange);

    _addFromStatusField(user['status'], add);

    final active = user['is_active'];
    if (active is bool) {
      add(active ? _active : _inactive);
    } else if (user['status'] == false) {
      add(_inactive);
    }

    if (result.isEmpty) add(_active);

    return result;
  }

  static void _addFromStatusField(
    dynamic status,
    void Function(StaffUserStatusInfo info) add,
  ) {
    if (status is List) {
      for (final item in status) {
        if (item == null) continue;
        add(_fromString('$item'));
      }
      return;
    }
    if (status is String && status.trim().isNotEmpty) {
      if (status.contains(',')) {
        for (final part in status.split(',')) {
          final s = part.trim();
          if (s.isNotEmpty) add(_fromString(s));
        }
      } else {
        add(_fromString(status.trim()));
      }
    }
  }

  /// Первый статус (для совместимости).
  static StaffUserStatusInfo fromUser(Map<String, dynamic> user) {
    final all = allFromUser(user);
    return all.first;
  }

  /// Строка для сортировки по колонке «Статус».
  static String sortKey(Map<String, dynamic> user) =>
      allFromUser(user).map((e) => e.label).join(' ').toLowerCase();

  static StaffUserStatusInfo _fromString(String raw) {
    final key = raw.toLowerCase();
    return switch (key) {
      'active' || 'активен' => _active,
      'inactive' || 'неактивен' || 'disabled' => _inactive,
      'test' || 'тест' => _test,
      'force_password_change' ||
      'force_password' ||
      'смена пароля' =>
        _forcePasswordChange,
      _ => StaffUserStatusInfo(
          label: _titleCase(raw),
          backgroundColor: const Color(0xFFEFF6FF),
          foregroundColor: const Color(0xFF1D4ED8),
        ),
    };
  }

  static String _titleCase(String raw) {
    if (raw.isEmpty) return raw;
    final lower = raw.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static const _active = StaffUserStatusInfo(
    label: 'Активен',
    backgroundColor: Color(0xFFDCFCE7),
    foregroundColor: Color(0xFF15803D),
  );

  static const _inactive = StaffUserStatusInfo(
    label: 'Неактивен',
    backgroundColor: Color(0xFFF1F5F9),
    foregroundColor: AppColors.grey,
  );

  static const _test = StaffUserStatusInfo(
    label: 'Тест',
    backgroundColor: Color(0xFFFEF3C7),
    foregroundColor: Color(0xFFB45309),
  );

  static const _forcePasswordChange = StaffUserStatusInfo(
    label: 'Смена пароля',
    backgroundColor: Color(0xFFFEE2E2),
    foregroundColor: Color(0xFFB91C1C),
  );
}
