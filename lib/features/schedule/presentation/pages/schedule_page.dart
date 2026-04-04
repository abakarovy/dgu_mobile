import 'package:dgu_mobile/core/constants/app_colors.dart';
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
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const Color _stripDayText = Color(0xFFFFFFFF);
  static const Color _stripNumMuted = Color(0x80FFFFFF);
  static const Color _stripSelected = Color(0xFF0069FF);

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppHeader(
              leadingLeftPadding: 6,
              leading: GestureDetector(
                onTap: () => context.pop(),
                behavior: HitTestBehavior.opaque,
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
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
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            offset: Offset(0, 3.75),
                            blurRadius: 18.75,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(7.5),
                      child: _buildWeekStrip(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _buildLessonsSection(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Полоса дней: ячейки 37.5×45, промежуток 27; при узком экране — горизонтальный скролл.
  Widget _buildWeekStrip() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cellW = 37.5;
        const gap = 27.0;
        const totalStripWidth = 7 * cellW + 6 * gap;

        final row = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int index = 0; index < 7; index++) ...[
              if (index > 0) const SizedBox(width: gap),
              _buildStripDayCell(index),
            ],
          ],
        );

        if (constraints.maxWidth >= totalStripWidth) {
          return Center(child: row);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: row,
        );
      },
    );
  }

  Widget _buildStripDayCell(int index) {
    final date = _dateFor(index);
    final isSelected = index == _selectedDayIndex;

    return GestureDetector(
      onTap: () => setState(() => _selectedDayIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 37.5,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? _stripSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(11.25),
        ),
        padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 11.25),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                SchedulePage._dayNames[index],
                textAlign: TextAlign.center,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 9.37,
                  height: 14.06 / 9.37,
                  color: _stripDayText,
                ),
              ),
              Text(
                '${date.day}',
                textAlign: TextAlign.center,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.25,
                  height: 1.0,
                  color: isSelected ? _stripDayText : _stripNumMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsSection() {
    final selectedDate = _dateFor(_selectedDayIndex);
    final items = lessonsForSelectedCalendarDay(_week, selectedDate);

    if (_loading && _week.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'Нет пар',
            textAlign: TextAlign.center,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.caption,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x120069FF),
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: _buildLessonsColumn(context, items),
    );
  }

  Widget _buildLessonsColumn(BuildContext context, List<ScheduleLesson> items) {
    final scale = ScheduleLessonTile.layoutScaleOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          ScheduleLessonTile(
            lesson: items[i],
            layoutScale: scale,
            showBottomDivider: i < items.length - 1,
            isFirstInList: i == 0,
          ),
      ],
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
