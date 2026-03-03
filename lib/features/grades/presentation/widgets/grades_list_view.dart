import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

import 'grade_item_tile.dart';

/// Элемент для отображения в списке оценок.
class GradeListItem {
  const GradeListItem({
    required this.subjectName,
    required this.grade,
    required this.subtitle,
  });

  final String subjectName;
  final String grade;
  final String subtitle;
}

/// Список оценок в виде карточек (как расписание на главной).
class GradesListView extends StatelessWidget {
  const GradesListView({
    super.key,
    required this.items,
  });

  final List<GradeListItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Нет оценок',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.caption,
              ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = items[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: GradeItemTile(
            subjectName: e.subjectName,
            grade: e.grade,
            subtitle: e.subtitle,
          ),
        );
      },
    );
  }
}
