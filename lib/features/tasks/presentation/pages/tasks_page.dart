import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/tasks_mock_data.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/task_card.dart';

/// Экран заданий: аппбар как у расписания, 2 таба (Активные / Завершенные), список карточек.
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  static const List<String> _tabLabels = ['Активные', 'Завершенные'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppHeader(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
            color: AppColors.textPrimary,
          ),
          headerTitle: Text(
            'Задания',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 24 / 18,
              color: AppColors.textPrimary,
            ),
          ),
          showNotificationIcon: false,
        ),
        body: Column(
          children: [
            Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppUi.screenPaddingH,
                    8,
                    AppUi.screenPaddingH,
                    12,
                  ),
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            for (int i = 0; i < 2; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _TasksTab(
                                  label: _tabLabels[i],
                                  selected: controller.index == i,
                                  onTap: () => controller.animateTo(i),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                children: [
                  _TasksList(items: activeTasks()),
                  _TasksList(items: completedTasks()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyle.inter(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
                height: 1.0,
                color: selected ? AppColors.primaryBlue : AppColors.caption,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TasksList extends StatelessWidget {
  const _TasksList({required this.items});

  final List<TaskItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Нет заданий',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.caption,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppUi.taskCardSpacing),
      itemBuilder: (context, index) {
        final task = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppUi.radiusS),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppUi.spacingM),
          child: TaskCard(
            task: task,
            onTap: () {},
          ),
        );
      },
    );
  }
}
