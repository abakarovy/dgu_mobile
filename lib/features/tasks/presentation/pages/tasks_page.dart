import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/assignment_model.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/network_degraded_banner.dart';
import '../widgets/task_card.dart';
import '../../data/task_item.dart';

/// Экран заданий: аппбар как у расписания, 2 таба (Активные / Завершенные), список карточек.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  static const List<String> _tabLabels = ['Активные', 'Завершенные'];

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool _loading = true;
  List<AssignmentModel> _items = const <AssignmentModel>[];

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
    _load();
  }

  void _hydrateFromCache() {
    try {
      final cached = AppContainer.jsonCache.getJsonList('mobile:assignments:my');
      if (cached != null) {
        _items = cached
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .map(AssignmentModel.fromJson)
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fresh = await AppContainer.assignmentsApi.getMy(limit: 50);
      await AppContainer.jsonCache.setJson('mobile:assignments:my', [
        for (final a in fresh)
          {
            'id': a.id,
            'title': a.title,
            'description': a.description,
            'subject': a.subject,
            'deadline_at': a.deadlineAt?.toIso8601String(),
            'created_at': a.createdAt?.toIso8601String(),
            'is_done': a.isDone,
          }
      ]);
      if (mounted) setState(() => _items = fresh);
    } catch (_) {
      // keep cache
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _deadlineText(AssignmentModel a) {
    final d = a.deadlineAt;
    if (d == null) return 'Без срока';
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(d.day)}.${p2(d.month)}.${d.year}';
  }

  static TaskItem _toTaskItem(AssignmentModel a) {
    return TaskItem(
      subjectName: (a.subject?.trim().isNotEmpty == true) ? a.subject!.trim() : 'Задание',
      title: a.title,
      deadlineText: _deadlineText(a),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _items.where((a) => a.isDone != true).toList();
    final done = _items.where((a) => a.isDone == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: DefaultTabController(
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
              ),
              body: RefreshIndicator(
                onRefresh: _load,
                child: Column(
                  children: [
                    if (_loading)
                      const LinearProgressIndicator(minHeight: 2),
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
                                          label: TasksPage._tabLabels[i],
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
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _TasksList(items: active.map(_toTaskItem).toList()),
                          _TasksList(items: done.map(_toTaskItem).toList()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(AppUi.screenPaddingH, 0, AppUi.screenPaddingH, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppUi.taskCardSpacing),
      itemBuilder: (context, i) => TaskCard(task: items[i]),
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

// List/TaskCard используются с бэком `/api/mobile/assignments/*`.
