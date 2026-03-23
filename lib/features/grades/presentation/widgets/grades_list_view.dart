import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:flutter/material.dart';

import 'grade_item_tile.dart';

/// Элемент для отображения в списке оценок.
class GradeListItem {
  const GradeListItem({
    required this.subjectName,
    required this.grade,
    required this.subtitle,
    this.date,
    this.type,
  });

  final String subjectName;
  final String grade;
  final String subtitle;
  final DateTime? date;
  final String? type;

  /// Типы, у которых текст окрашивается в цвет оценки (контрольная, аттестация и т.д.).
  static const specialTypes = {
    'Контрольная работа',
    'Аттестационная работа',
    'Промежуточная аттестация',
    'Экзамен',
    'Зачёт',
  };

  bool get isSpecialType => type != null && specialTypes.contains(type);
}

/// Список оценок в виде карточек (как расписание на главной).
class GradesListView extends StatelessWidget {
  const GradesListView({
    super.key,
    required this.items,
    this.groupByDate = false,
    this.onSubjectTap,
  });

  final List<GradeListItem> items;
  final bool groupByDate;
  final void Function(String subjectName)? onSubjectTap;

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

    if (groupByDate && items.any((e) => e.date != null)) {
      final groups = <DateTime, List<GradeListItem>>{};
      for (final e in items) {
        if (e.date != null) {
          final d = DateTime(e.date!.year, e.date!.month, e.date!.day);
          groups[d] ??= [];
          groups[d]!.add(e);
        }
      }
      final dates = groups.keys.toList()..sort();
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final groupItems = groups[date]!;
          return _DateGroup(
            date: date,
            items: groupItems,
            onSubjectTap: onSubjectTap,
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppUi.spacingM),
      itemBuilder: (context, index) {
        final e = items[index];
        return _GradeCard(item: e, onTap: onSubjectTap != null ? () => onSubjectTap!(e.subjectName) : null);
      },
    );
  }
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.date,
    required this.items,
    this.onSubjectTap,
  });

  final DateTime date;
  final List<GradeListItem> items;
  final void Function(String subjectName)? onSubjectTap;

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];
  static const _weekdays = [
    'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье',
  ];

  @override
  Widget build(BuildContext context) {
    final dateStr = '${date.day} ${_months[date.month - 1]}';
    final weekdayStr = _weekdays[date.weekday - 1];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUi.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weekdayStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.caption,
                  ),
                ),
              ],
            ),
          ),
          ...items.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: AppUi.spacingM),
            child: _GradeCard(
              item: e,
              onTap: onSubjectTap != null ? () => onSubjectTap!(e.subjectName) : null,
            ),
          )),
        ],
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.item, this.onTap});

  final GradeListItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUi.radiusS),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppUi.radiusS),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppUi.contentPaddingH, vertical: AppUi.contentPaddingV),
          child: GradeItemTile(
            subjectName: item.subjectName,
            grade: item.grade,
            subtitle: item.subtitle,
            type: item.type,
            isSpecialType: item.isSpecialType,
          ),
        ),
      ),
    );
  }
}
