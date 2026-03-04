import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Один элемент списка оценок: дисциплина, преподаватель (subtitle), справа — оценка в контейнере.
class GradeItemTile extends StatelessWidget {
  const GradeItemTile({
    super.key,
    required this.subjectName,
    required this.grade,
    required this.subtitle,
  });

  final String subjectName;
  final String grade;
  final String subtitle;

  static (Color textColor, Color bgColor) _colorsForGrade(String grade) {
    final g = grade.trim();
    if (g == '5') return (AppColors.grade5Text, AppColors.grade5Bg);
    if (g == '4') return (AppColors.grade4Text, AppColors.grade4Bg);
    if (g == '3') return (AppColors.grade3Text, AppColors.grade3Bg);
    if (g == '2' || g == '1') return (AppColors.grade2Text, AppColors.grade2Bg);
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
    final (gradeTextColor, gradeBgColor) = _colorsForGrade(grade);
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
                  fontSize: 16,
                  height: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                  height: 1.0,
                  color: AppColors.caption,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppUi.spacingM),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: gradeBgColor,
            borderRadius: BorderRadius.circular(AppUi.radiusL),
          ),
          alignment: Alignment.center,
          child: Text(
            grade,
            textAlign: TextAlign.center,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.0,
              color: gradeTextColor,
            ),
          ),
        ),
      ],
    );
  }
}
