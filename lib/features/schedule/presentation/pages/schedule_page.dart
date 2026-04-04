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

  static const List<String> _dayNames = [
    'ПН',
    'ВТ',
    'СР',
    'ЧТ',
    'ПТ',
    'СБ',
    'ВС',
  ];
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
    final m = DateTime(
      _mondayOfWeek.year,
      _mondayOfWeek.month,
      _mondayOfWeek.day,
    );
    return m.add(Duration(days: index));
  }

  @override
  Widget build(BuildContext context) {
    final layoutScale = ScheduleLessonTile.layoutScaleOf(context);
    final screenW = MediaQuery.sizeOf(context).width;
    // Боковые отступы экрана: от ширины окна (узкие телефоны — меньше, шире — больше, с потолком).
    final hPad = (screenW * 0.038).clamp(12.0, 28.0);
    final stripBlockGap = 32.0 * layoutScale;

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
              padding: EdgeInsets.only(bottom: 30 * layoutScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 16 * layoutScale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final s = layoutScale;
                        final cellW = 37.5 * s;
                        final gap = 14.0 * s;
                        final stripTotalW = 7 * cellW + 6 * gap;
                        // Внутренние отступы контейнера с датами: слева/справа — от ширины полосы.
                        final padV = 7.5 * s;
                        final padSide = (constraints.maxWidth * 0.028)
                            .clamp(6.0 * s, 14.0 * s);
                        final innerPadH = padSide * 2;
                        final rowMaxW = constraints.maxWidth - innerPadH;

                        final row = Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            for (int index = 0; index < 7; index++) ...[
                              if (index > 0) SizedBox(width: gap),
                              _buildStripDayCell(index, s),
                            ],
                          ],
                        );

                        return Container(
                          height: 60 * s,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(15 * s),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x0A000000),
                                offset: Offset(0, 3.75 * s),
                                blurRadius: 18.75 * s,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: padSide,
                            vertical: padV,
                          ),
                          child: rowMaxW < stripTotalW
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: row,
                                )
                              : Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: row,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: stripBlockGap),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _buildLessonsSection(layoutScale),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStripDayCell(int index, double stripScale) {
    final date = _dateFor(index);
    final isSelected = index == _selectedDayIndex;
    final dayFs = 9.37 * stripScale;
    final numFs = 11.25 * stripScale;

    return GestureDetector(
      onTap: () => setState(() => _selectedDayIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 37.5 * stripScale,
        height: 45 * stripScale,
        decoration: BoxDecoration(
          color: isSelected ? _stripSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(11.25 * stripScale),
        ),
        padding: EdgeInsets.symmetric(
          vertical: 7.5 * stripScale,
          horizontal: 11.25 * stripScale,
        ),
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
                  fontSize: dayFs,
                  height: 14.06 / 9.37,
                  color: _stripDayText,
                ),
              ),
              Text(
                '${date.day}',
                textAlign: TextAlign.center,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: numFs,
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

  Widget _buildLessonsSection(double layoutScale) {
    final selectedDate = _dateFor(_selectedDayIndex);
    final items = lessonsForSelectedCalendarDay(_week, selectedDate);

    if (_loading && _week.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 48 * layoutScale),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 48 * layoutScale),
        child: Center(
          child: Text(
            'Нет пар',
            textAlign: TextAlign.center,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14 * layoutScale,
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
        borderRadius: BorderRadius.circular(26 * layoutScale),
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, 12 * layoutScale),
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
      final fresh = await AppContainer.scheduleApi.getWeekForCalendar(
        _mondayOfWeek,
      );
      await AppContainer.jsonCache.setJson(cacheKey, [
        for (final l in fresh) l.toJsonMap(),
      ]);
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
