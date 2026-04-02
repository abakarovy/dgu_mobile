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
  static (Color textColor, Color bgColor) colorsForGrade(String grade) {
    final g = grade.trim();
    if (g == '5') return (const Color(0xFF10B981), const Color(0x2B10B981));
    if (g == '4') return (const Color(0xFFDF9D3F), const Color(0x2BFFD900));
    if (g == '3') return (const Color(0xFF3B82F6), const Color(0x2B3B82F6)); // придумали для 3
    if (g == '2' || g == '1') return (const Color(0xFFC84547), const Color(0x26C84547));
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
