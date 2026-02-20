import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Один элемент списка оценок: дисциплина и подпись (оценка • преподаватель/дата).
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          subjectName,
          style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '$grade • $subtitle',
          style: theme.bodySmall?.copyWith(color: AppColors.caption),
        ),
      ],
    );
  }
}
