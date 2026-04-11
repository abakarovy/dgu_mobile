import 'dart:async';
import 'dart:convert';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

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
  /// Визуальный масштаб боковых стрелок относительно базового (0.75 ≈ −25% к полному размеру).
  static const double _weekNavArrowVisualScale = 0.75;

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

  void _shiftWeek(int deltaDays) {
    setState(() {
      _mondayOfWeek = DateTime(
        _mondayOfWeek.year,
        _mondayOfWeek.month,
        _mondayOfWeek.day,
      ).add(Duration(days: deltaDays));
      _week = const <ScheduleLesson>[];
      _loading = true;
    });
    unawaited(_loadFromCacheThenRefresh());
  }

  @override
  Widget build(BuildContext context) {
    final layoutScale = ScheduleLessonTile.layoutScaleOf(context);
    final screenW = MediaQuery.sizeOf(context).width;
    // Боковые отступы экрана: от ширины окна (узкие телефоны — меньше, шире — больше, с потолком).
    final hPad = (screenW * 0.038).clamp(12.0, 28.0);
    // У строки недели со стрелками — меньше отступ к краям окна, чем у списка пар.
    final weekStripRowHPad = (hPad * 0.52).clamp(6.0, 16.0);
    final stripBlockGap = 32.0 * layoutScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppHeader(
              leading: appHeaderNestedBackLeading(context),
              headerTitle:
                  Text('Расписание', style: appHeaderNestedTitleStyle),
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 30 * layoutScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 16 * layoutScale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: weekStripRowHPad),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                          ),
                          constraints: BoxConstraints(
                            minWidth:
                                40 * layoutScale * _weekNavArrowVisualScale,
                            minHeight:
                                48 * layoutScale * _weekNavArrowVisualScale,
                          ),
                          onPressed: _loading ? null : () => _shiftWeek(-7),
                          icon: Icon(
                            Icons.chevron_left,
                            size: 28 * layoutScale * _weekNavArrowVisualScale,
                            color: _loading
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final s = layoutScale;
                              final cellW = 37.5 * s;
                              final gap = 14.0 * s;
                              final stripTotalW = 7 * cellW + 6 * gap;
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
                        IconButton(
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                          ),
                          constraints: BoxConstraints(
                            minWidth:
                                40 * layoutScale * _weekNavArrowVisualScale,
                            minHeight:
                                48 * layoutScale * _weekNavArrowVisualScale,
                          ),
                          onPressed: _loading ? null : () => _shiftWeek(7),
                          icon: Icon(
                            Icons.chevron_right,
                            size: 28 * layoutScale * _weekNavArrowVisualScale,
                            color: _loading
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
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
    final cacheKey = ScheduleApi.weekCalendarCacheKey(_mondayOfWeek);
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
      final sid = await _linkedStudentIdForScheduleApi();
      final fresh = await AppContainer.scheduleApi.getWeekForCalendar(
        _mondayOfWeek,
        studentId: sid,
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

  /// Родитель: `GET /api/1c/schedule` требует `student_id` ребёнка.
  Future<int?> _linkedStudentIdForScheduleApi() async {
    try {
      final raw = await AppContainer.tokenStorage.getUserDataJson();
      if (raw == null || raw.isEmpty) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if ((m['role'] ?? '').toString().trim().toLowerCase() != 'parent') {
        return null;
      }
      final sd = AppContainer.jsonCache.getJsonMap('parents:student-data');
      final st = sd?['student'];
      if (st is Map) {
        final id = st['id'];
        if (id is int) return id;
        if (id is num) return id.toInt();
      }
      final ls = await AppContainer.accountApi.getParentsLinkStatus();
      final s = ls['student_id'];
      if (s is int) return s;
      if (s is num) return s.toInt();
    } catch (_) {}
    return null;
  }
}
