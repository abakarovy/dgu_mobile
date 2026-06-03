import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Один элемент списка оценок: название предмета, подпись (тип работы или преподаватель), справа — оценка.
class GradeItemTile extends StatelessWidget {
  const GradeItemTile({
    super.key,
    required this.subjectName,
    required this.grade,
    required this.subtitle,
    this.type,
    this.isSpecialType = false,
  });

  final String subjectName;
  final String grade;
  final String subtitle;
  final String? type;
  final bool isSpecialType;

  /// Публичный для использования в subject_grades_sheet.
  static String? normalizeToGradeCode(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (RegExp(r'^[1-5]$').hasMatch(t)) return t;
    final lower = t.toLowerCase();
    if (lower.contains('неуд') || lower.contains('незач')) return '2';
    if (lower.contains('удовл')) return '3';
    if (lower.contains('хор')) return '4';
    if (lower.contains('отл') || lower.contains('зач')) return '5';
    return null;
  }

  static (Color textColor, Color bgColor) _colorsForCode(String code) {
    switch (code) {
      case '5':
        return (AppColors.grade5Text, AppColors.grade5Bg);
      case '4':
        return (AppColors.grade4Text, AppColors.grade4Bg);
      case '3':
        return (AppColors.grade3Text, AppColors.grade3Bg);
      case '2':
      case '1':
        return (AppColors.grade2Text, AppColors.grade2Bg);
      default:
        return (AppColors.gradeDefaultText, AppColors.gradeDefaultBg);
    }
  }

  /// Цвета чипа на вкладке «Сессия» (с полупрозрачным фоном и обводкой).
  static (Color text, Color bg, Color border) colorsForGradeChip(String grade) {
    final (text, _) = colorsForGrade(grade);
    if (normalizeToGradeCode(grade) != null ||
        double.tryParse(grade.trim().replaceFirst(',', '.')) != null) {
      return (text, text.withValues(alpha: 0.11), text);
    }
    return (
      AppColors.gradeDefaultText,
      AppColors.gradeDefaultBg,
      AppColors.lightGrey,
    );
  }

  /// Публичный для использования в subject_grades_sheet.
  static (Color textColor, Color bgColor) colorsForGrade(String grade) {
    final code = normalizeToGradeCode(grade);
    if (code != null) return _colorsForCode(code);

    final g = grade.trim();
    // Средний балл (4.67 и т.д.) — цвет по диапазону
    final value = double.tryParse(g.replaceFirst(',', '.'));
    if (value != null) {
      if (value >= 4.5) return (AppColors.grade5Text, AppColors.grade5Bg);
      if (value >= 3.5) return (AppColors.grade4Text, AppColors.grade4Bg);
      if (value >= 2.5) return (AppColors.grade3Text, AppColors.grade3Bg);
      if (value >= 1.5) return (AppColors.grade2Text, AppColors.grade2Bg);
      return (AppColors.grade2Text, AppColors.grade2Bg);
    }
    return (AppColors.gradeDefaultText, AppColors.gradeDefaultBg);
  }

  @override
  Widget build(BuildContext context) {
    final (gradeTextColor, gradeBgColor) = colorsForGrade(grade);
    final subtitleText = type ?? subtitle;
    final subtitleColor = isSpecialType ? gradeTextColor : const Color(0xFF929292);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subjectName,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.15,
                  height: 1.0,
                  color: const Color(0xFF000000),
                ),
              ),
              if (subtitleText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 10.48,
                    height: 15.72 / 10.48,
                    color: subtitleColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppUi.spacingM),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: gradeBgColor,
            borderRadius: BorderRadius.circular(6.2),
          ),
          alignment: Alignment.center,
          child: Text(
            grade,
            textAlign: TextAlign.center,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 19.72,
              height: 1.0,
              color: gradeTextColor,
            ),
          ),
        ),
      ],
    );
  }
}
