import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/schedule_mock_data.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/schedule_lesson_tile.dart';

/// Экран расписания: аппбар как у уведомлений, неделя (ПН–ВС), дата, список пар.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  static const List<String> _dayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
  static const List<String> _weekdayNamesFull = [
    'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье',
  ];
  static const List<String> _monthNames = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _mondayOfWeek;
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _selectedDayIndex = now.weekday - 1;
  }

  DateTime _dateFor(int index) => _mondayOfWeek.add(Duration(days: index));

  /// Формат: "ВТОРНИК, 12 МАЯ" (все заглавными).
  String _formatDateCaption(DateTime d, int weekdayIndex) {
    final weekday = SchedulePage._weekdayNamesFull[weekdayIndex].toUpperCase();
    final month = SchedulePage._monthNames[d.month - 1].toUpperCase();
    return '$weekday, ${d.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        headerTitle: Text(
          'Расписание',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 24 / 18,
            color: AppColors.textPrimary,
          ),
        ),
        showNotificationIcon: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppUi.spacingXl),
            _buildWeekStrip(),
            const SizedBox(height: 24),
            _buildDateCaption(),
            const SizedBox(height: AppUi.spacingM),
            _buildLessonsList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStrip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final date = _dateFor(index);
        final isSelected = index == _selectedDayIndex;
        return Padding(
          padding: EdgeInsets.only(
            right: index < 6 ? AppUi.scheduleDayCellSpacing : 0,
          ),
          child: GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              width: AppUi.scheduleDayCellWidth,
              height: AppUi.scheduleDayCellHeight,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.notificationSwitchActive
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(AppUi.scheduleDayCellRadius),
                boxShadow: isSelected
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    SchedulePage._dayNames[index],
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 15 / 10,
                      color: isSelected
                          ? Colors.white
                          : AppColors.notificationSubtitle,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 15 / 10,
                      color: isSelected
                          ? Colors.white
                          : AppColors.notificationSubtitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDateCaption() {
    final date = _dateFor(_selectedDayIndex);
    return Text(
      _formatDateCaption(date, _selectedDayIndex),
      style: AppTextStyle.inter(
        fontWeight: FontWeight.w800,
        fontSize: 11,
        height: 16.5 / 11,
        letterSpacing: 1.65,
        color: AppColors.caption,
      ),
    );
  }

  Widget _buildLessonsList() {
    final items = scheduleLessonsForDay(_selectedDayIndex);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          'Нет пар',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.caption,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppUi.spacingBetweenCards),
          child: Container(
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
            child: ScheduleLessonTile(lesson: e),
          ),
        );
      }).toList(),
    );
  }
}
