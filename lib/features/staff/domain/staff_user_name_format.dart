import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Форматирование ФИО для списков: по строкам, первая буква заглавная.
abstract final class StaffUserNameFormat {
  static bool isPlaceholderToken(String token) {
    final t = token.trim();
    if (t.isEmpty) return true;
    if (t == '—' || t == '-' || t == '–' || t == '−') return true;
    final lower = t.toLowerCase();
    return lower == 'родитель' || lower == 'parent';
  }

  static String rawFromUser(Map<String, dynamic> user) {
    final full = (user['full_name'] ?? '').toString().trim();
    final fio = (user['fio'] ?? '').toString().trim();
    if (full.isNotEmpty && !isPlaceholderToken(full)) return full;
    if (fio.isNotEmpty && !isPlaceholderToken(fio)) return fio;
    return full.isNotEmpty ? full : fio;
  }

  static String titleCaseWord(String word) {
    final w = word.trim();
    if (w.isEmpty) return w;
    final lower = w.toLowerCase();
    if (lower.length == 1) return lower.toUpperCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  /// Фамилия, имя, отчество — каждая часть с новой строки.
  static List<String> linesFromUser(Map<String, dynamic> user) {
    final raw = rawFromUser(user);
    if (raw.isEmpty || isPlaceholderToken(raw)) return const ['—'];
    final tokens = raw
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty && !isPlaceholderToken(s))
        .toList();
    if (tokens.isEmpty) return const ['—'];
    return tokens.map(titleCaseWord).toList();
  }

  /// Однострочное ФИО: каждое слово с заглавной буквы.
  static String displayNameFromUser(Map<String, dynamic> user) {
    return linesFromUser(user).join(' ');
  }
}

/// ФИО в колонке таблицы: фамилия / имя / отчество.
class StaffUserFioColumn extends StatelessWidget {
  const StaffUserFioColumn({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final lines = StaffUserNameFormat.linesFromUser(user);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines.length; i++)
          Text(
            lines[i],
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.25,
              color: AppColors.textPrimary,
            ),
          ),
      ],
    );
  }
}
