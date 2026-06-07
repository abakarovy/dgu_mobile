import 'package:flutter/material.dart';

/// Подпись уровня риска группы (как на сайте).
String departmentRiskLabel(String? riskLevel) {
  final r = (riskLevel ?? 'low').toLowerCase();
  return switch (r) {
    'high' || 'critical' => 'РИСК: ВЫСОКИЙ',
    'medium' || 'attention' => 'РИСК: СРЕДНИЙ — ВНИМАНИЕ',
    _ => 'РИСК: НИЗКИЙ',
  };
}

Color departmentRiskColor(String? riskLevel) {
  final r = (riskLevel ?? 'low').toLowerCase();
  return switch (r) {
    'high' || 'critical' => const Color(0xFFDC2626),
    'medium' || 'attention' => const Color(0xFFD97706),
    _ => const Color(0xFF059669),
  };
}

bool departmentGroupIsCritical(Map<String, dynamic> group) {
  final risk = (group['risk_level'] ?? 'low').toString().toLowerCase();
  if (risk == 'high' || risk == 'critical' || risk == 'medium' || risk == 'attention') {
    return true;
  }
  final att = group['attendance_percent'];
  if (att is num && att < 80) return true;
  return false;
}

String departmentFormatPercent(num? value) {
  if (value == null) return '—';
  if (value == value.roundToDouble()) return '${value.round()}%';
  return '${value.toStringAsFixed(1)}%';
}

/// Целые числа с пробелом между тысячами: 16845 → 16 845.
String departmentFormatInt(num? value) {
  if (value == null) return '—';
  final s = value.round().abs().toString();
  final negative = value.round() < 0;
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  final formatted = buf.toString();
  return negative ? '-$formatted' : formatted;
}

/// Группировка групп по куратору для вкладки «Кураторы».
List<({String curator, List<Map<String, dynamic>> groups})> departmentCuratorsFromGroups(
  List<Map<String, dynamic>> groups,
) {
  final byCurator = <String, List<Map<String, dynamic>>>{};
  for (final g in groups) {
    final name = (g['curator_full_name'] ?? 'Без куратора').toString().trim();
    final key = name.isEmpty ? 'Без куратора' : name;
    byCurator.putIfAbsent(key, () => []).add(g);
  }
  final entries = byCurator.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return [
    for (final e in entries) (curator: e.key, groups: e.value),
  ];
}
