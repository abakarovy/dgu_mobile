import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/schedule_lesson.dart';
import '../../domain/schedule_calendar_filter.dart';
import '../../../../core/di/app_container.dart';
import '../../../../data/api/schedule_api.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/network_degraded_banner.dart';
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
  List<ScheduleLesson> _week = const <ScheduleLesson>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mondayOfWeek = ScheduleApi.mondayOfWeekContaining(now);
    _selectedDayIndex = now.weekday - 1;
    _loadFromCacheThenRefresh();
  }

  DateTime _dateFor(int index) {
    final m = DateTime(_mondayOfWeek.year, _mondayOfWeek.month, _mondayOfWeek.day);
    return m.add(Duration(days: index));
  }

  /// Формат: "ВТОРНИК, 12 МАЯ" (все заглавными).
  String _formatDateCaption(DateTime d, int weekdayIndex) {
    final weekday = SchedulePage._weekdayNamesFull[weekdayIndex].toUpperCase();
    final month = SchedulePage._monthNames[d.month - 1].toUpperCase();
    return '$weekday, ${d.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
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
          ),
        ),
      ],
    );
  }

  Widget _buildWeekStrip() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < 7; index++) ...[
          if (index > 0) SizedBox(width: AppUi.scheduleDayCellSpacing),
          Expanded(child: _buildDayCell(index)),
        ],
      ],
    );
  }

  Widget _buildDayCell(int index) {
    final date = _dateFor(index);
    final isSelected = index == _selectedDayIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedDayIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: AppUi.scheduleDayCellHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.notificationSwitchActive
              : Colors.white,
          borderRadius: BorderRadius.circular(AppUi.scheduleDayCellRadius),
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
    final selectedDate = _dateFor(_selectedDayIndex);
    final items = lessonsForSelectedCalendarDay(_week, selectedDate);
    if (_loading && _week.isEmpty) {
      // На первом запуске, если по какой-то причине кэша нет.
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return _buildLessonsColumn(items);
  }

  Widget _buildLessonsColumn(List<ScheduleLesson> items) {
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

  Future<void> _loadFromCacheThenRefresh() async {
    // v2: неделя из нескольких запросов `GET /1c/schedule?for_date=…`.
    const cacheKey = 'schedule:week:v2';
    // 1) Мгновенно рисуем кэш (он прогревается на splash).
    final cached = AppContainer.jsonCache.getJsonList(cacheKey);
    if (cached != null) {
      final list = cached
          .whereType<Map>()
          .map((m) => ScheduleLesson.fromJsonMap(Map<String, dynamic>.from(m)))
          .toList();
      if (mounted) {
        setState(() {
          _week = list;
          _loading = false;
        });
      }
    }

    // 2) Тихо обновляем из сети (без блокировки UI).
    try {
      final fresh = await AppContainer.scheduleApi
          .getWeekForCalendar(_mondayOfWeek);
      await AppContainer.jsonCache.setJson(
        cacheKey,
        [for (final l in fresh) l.toJsonMap()],
      );
      if (mounted) {
        setState(() {
          _week = fresh;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
}
