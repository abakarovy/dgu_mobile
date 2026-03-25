import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../models/session_grade_breakdown.dart';
import 'grade_item_tile.dart';

/// Карточка сессии: ряды собираются по ширине текста без […]; при нехватке места чип переносится на следующий ряд.
class SessionGradeItemTile extends StatelessWidget {
  static const double _layoutFudge = 12;

  const SessionGradeItemTile({
    super.key,
    required this.subjectName,
    required this.breakdown,
  });

  final String subjectName;
  final SessionGradeBreakdown breakdown;

  static const List<({String key, String label})> _keys = [
    (key: 'att1', label: 'Атт 1'),
    (key: 'att2', label: 'Атт 2'),
    (key: 'dfk', label: 'ДФК'),
    (key: 'kurs', label: 'Кур'),
    (key: 'zach', label: 'Зач'),
    (key: 'ekz', label: 'Экз'),
  ];

  String? _raw(String key) {
    switch (key) {
      case 'att1':
        return breakdown.att1;
      case 'att2':
        return breakdown.att2;
      case 'dfk':
        return breakdown.dfk;
      case 'kurs':
        return breakdown.kurs;
      case 'zach':
        return breakdown.zach;
      case 'ekz':
        return breakdown.ekz;
      default:
        return null;
    }
  }

  List<({String label, String value})> _filled() {
    final out = <({String label, String value})>[];
    for (final e in _keys) {
      final v = _raw(e.key);
      if (v == null || v.trim().isEmpty) continue;
      out.add((label: e.label, value: v.trim()));
    }
    return out;
  }

  /// Индексы чипов, сгруппированные в строки по [maxW] (жадно, без «…»).
  static List<List<int>> _packRows(List<double> widths, double maxW, double gap) {
    final rows = <List<int>>[];
    var i = 0;
    while (i < widths.length) {
      final row = <int>[];
      var sum = 0.0;
      while (i < widths.length) {
        final w = widths[i];
        final add = row.isEmpty ? w : w + gap;
        if (sum + add > maxW + 0.5) {
          if (row.isEmpty) {
            row.add(i);
            i++;
          }
          break;
        }
        row.add(i);
        sum += add;
        i++;
      }
      if (row.isEmpty) break;
      rows.add(row);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filled();
    const gap = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          subjectName,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            height: 1.25,
            color: AppColors.textPrimary,
          ),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final widths = [
                for (final e in items)
                  _SessionPill.intrinsicWidth(context, e.label, e.value),
              ];
              final rowIndices = _packRows(widths, maxW - _layoutFudge, gap);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var r = 0; r < rowIndices.length; r++) ...[
                    if (r > 0) const SizedBox(height: gap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var c = 0; c < rowIndices[r].length; c++) ...[
                          if (c > 0) const SizedBox(width: gap),
                          Expanded(
                            flex: widths[rowIndices[r][c]].ceil().clamp(1, 1000000),
                            child: _SessionPill(
                              label: items[rowIndices[r][c]].label,
                              value: items[rowIndices[r][c]].value,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _SessionPill extends StatelessWidget {
  const _SessionPill({required this.label, required this.value});

  final String label;
  final String value;

  /// Горизонтальные отступы + одна строка «label · value».
  static double intrinsicWidth(BuildContext context, String label, String value) {
    final (valueColor, _, _) = _colorsFor(value);
    final isGrade = _gradeCodeForValue(value) != null;
    final labelColor = isGrade
        ? valueColor.withValues(alpha: 0.85)
        : AppColors.notificationSubtitle;
    final tp = TextPainter(
      text: TextSpan(
        style: AppTextStyle.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          height: 1.25,
          color: labelColor,
        ),
        children: [
          TextSpan(text: label),
          TextSpan(
            text: ' · ',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: AppColors.caption,
            ),
          ),
          TextSpan(
            text: value,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              height: 1.25,
              color: valueColor,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    return 24 + tp.width;
  }

  /// неуд → 2, удовл → 3, хор → 4, отл → 5; цифры 1–5 как есть.
  static String? _gradeCodeForValue(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (RegExp(r'^[1-5]$').hasMatch(t)) return t;
    final lower = t.toLowerCase();
    if (lower == 'неуд') return '2';
    if (lower == 'удовл') return '3';
    if (lower == 'хор') return '4';
    if (lower == 'отл') return '5';
    return null;
  }

  static (Color text, Color bg, Color border) _colorsFor(String value) {
    final code = _gradeCodeForValue(value);
    if (code != null) {
      final (text, bg) = GradeItemTile.colorsForGrade(code);
      final border = Color.lerp(text, bg, 0.35)!;
      return (text, bg, border);
    }
    // аттестации и пр. — как раньше, нейтраль + синий акцент
    return (
      AppColors.primaryBlue,
      AppColors.backgroundBlue,
      const Color(0x332563EB),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (valueColor, bg, borderColor) = _colorsFor(value);
    final isGrade = _gradeCodeForValue(value) != null;
    final labelColor = isGrade
        ? valueColor.withValues(alpha: 0.85)
        : AppColors.notificationSubtitle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.25,
            color: labelColor,
          ),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: ' · ',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: AppColors.caption,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.25,
                color: valueColor,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
