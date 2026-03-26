import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../data/schedule_lesson.dart';

/// Карточка одной пары в списке расписания.
class ScheduleLessonTile extends StatelessWidget {
  const ScheduleLessonTile({super.key, required this.lesson});

  final ScheduleLesson lesson;

  @override
  Widget build(BuildContext context) {
    final subjectStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 1.0,
      color: AppColors.textPrimary,
    );
    final captionStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.0,
      color: AppColors.caption,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(lesson.subject, style: subjectStyle),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${lesson.time} • ${lesson.teacher}', style: captionStyle),
            Text(lesson.auditorium, style: captionStyle),
          ],
        ),
      ],
    );
  }
}
