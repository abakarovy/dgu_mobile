import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../models/session_grade_breakdown.dart';
import 'grade_item_tile.dart';
import 'session_grade_item_tile.dart';

/// Элемент для отображения в списке оценок.
class GradeListItem {
  const GradeListItem({
    required this.subjectName,
    required this.grade,
    required this.subtitle,
    this.date,
    this.type,
    this.sessionBreakdown,
  });

  final String subjectName;
  final String grade;
  final String subtitle;
  final DateTime? date;
  final String? type;

  /// Если задано — вкладка «Сессия»: карточка с аттестациями и формами (не общий вид с оценкой справа).
  final SessionGradeBreakdown? sessionBreakdown;

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
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 15),
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

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    final first = s[0].toUpperCase();
    if (s.length == 1) return first;
    return '$first${s.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${date.day} ${_months[date.month - 1]}';
    final weekdayStr = _capitalizeFirst(_weekdays[date.weekday - 1]);
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
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 19.47,
                    height: 1.0,
                    color: const Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weekdayStr,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.59,
                    height: 1.0,
                    color: const Color(0xAB4B4B4B),
                  ),
                ),
              ],
            ),
          ),
          ...items.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
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
        borderRadius: BorderRadius.circular(97.3),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(97.3),
            color: const Color(0xFFFFFFFF),
            border: Border.all(
              color: const Color(0x24000000),
              width: 0.46,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x24000000),
                offset: const Offset(1.39, 1.85),
                blurRadius: 6.39,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: AppUi.contentPaddingV),
          child: item.sessionBreakdown != null
              ? SessionGradeItemTile(
                  subjectName: item.subjectName,
                  breakdown: item.sessionBreakdown!,
                )
              : GradeItemTile(
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
