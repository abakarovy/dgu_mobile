import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

import '../widgets/grades_list_view.dart';

/// Вкладка «Оценки»: 3 таба (Текущие, Сессия, Итого), список оценок в стиле расписания.
class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  static const List<String> _tabLabels = ['Текущие', 'Сессия', 'Итого'];

  static List<GradeListItem> _currentGrades = const [
    GradeListItem(
      subjectName: 'Веб разработка',
      grade: '5',
      subtitle: 'Алиева А.М.',
    ),
    GradeListItem(
      subjectName: 'Базы данных',
      grade: '4',
      subtitle: 'Иванов И.И.',
    ),
    GradeListItem(
      subjectName: 'Математика',
      grade: '5',
      subtitle: 'Петрова П.П.',
    ),
  ];

  static List<GradeListItem> _semesterGrades = const [
    GradeListItem(
      subjectName: 'Веб разработка',
      grade: '5',
      subtitle: 'Зачёт, 20.01.2025',
    ),
    GradeListItem(
      subjectName: 'Базы данных',
      grade: '4',
      subtitle: 'Экзамен, 22.01.2025',
    ),
  ];

  static List<GradeListItem> _totalGrades = const [
    GradeListItem(
      subjectName: 'Средний балл',
      grade: '4.67',
      subtitle: 'за семестр',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final controller = DefaultTabController.of(context)!;
                return ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    return Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Row(
                        children: [
                          for (int i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _GradesTab(
                                label: _tabLabels[i],
                                selected: controller.index == i,
                                onTap: () => controller.animateTo(i),
                              ),
                            ),
                          ],
                        ],
                      )
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                KeyedSubtree(
                  key: const ValueKey<String>('grades_current'),
                  child: GradesListView(items: _currentGrades),
                ),
                KeyedSubtree(
                  key: const ValueKey<String>('grades_semester'),
                  child: GradesListView(items: _semesterGrades),
                ),
                KeyedSubtree(
                  key: const ValueKey<String>('grades_total'),
                  child: GradesListView(items: _totalGrades),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradesTab extends StatelessWidget {
  const _GradesTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        splashColor: AppColors.surfaceLight,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, ),
          child: Center(
            child: Text(
              label,
              style: theme.labelLarge?.copyWith(
                color: selected ? AppColors.primaryBlue : AppColors.caption,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}