import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../schedule/data/schedule_lesson.dart';
import '../../../schedule/presentation/widgets/schedule_lesson_tile.dart';
import '../../../../core/di/app_container.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../grades/domain/entities/grade_entity.dart';
import '../widgets/home_hero_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<_BannerData> _bannerFuture;
  late final Future<int> _todayCountFuture;
  late final Future<List<ScheduleLesson>> _todayLessonsFuture;

  @override
  void initState() {
    super.initState();
    final todayIndex = DateTime.now().weekday - 1;
    _bannerFuture = _loadBannerData();
    _todayCountFuture = _loadTodayCount(todayIndex);
    _todayLessonsFuture = _loadTodayLessons(todayIndex);
  }

  static TextStyle _cardTitleStyle(BuildContext context) => AppTextStyle.inter(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.0,
    color: AppColors.textPrimary,
  );

  static TextStyle _cardSubtitleStyle(BuildContext context) => AppTextStyle.inter(
    fontWeight: FontWeight.w400,
    fontSize: 10,
    height: 1.0,
    color: AppColors.caption,
  );

  /// Компактные отступы и шрифты на узких экранах.
  static bool _compactHome(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 400;

  static EdgeInsets _cardPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return const EdgeInsets.all(12);
    if (w < 400) return const EdgeInsets.all(14);
    return AppUi.homeCardPadding;
  }

  Widget _iconCaptionCard(
    BuildContext context,
    Widget child, {
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(_cardPadding(context)),
        alignment: AlignmentGeometry.centerLeft,
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      onPressed: onPressed ?? () {},
      child: child,
    );
  }

  TextStyle _cardTitleStyleFor(BuildContext context) {
    final base = _cardTitleStyle(context);
    if (_compactHome(context)) {
      return base.copyWith(fontSize: 14);
    }
    return base;
  }

  TextStyle _cardSubtitleStyleFor(BuildContext context) {
    final base = _cardSubtitleStyle(context);
    if (_compactHome(context)) {
      return base.copyWith(fontSize: 9);
    }
    return base;
  }

  Widget _scheduleButton(BuildContext context) {
    return FutureBuilder<int>(
      future: _todayCountFuture,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        final compact = _compactHome(context);
        final iconPad = compact ? 8.0 : 10.0;
        final iconSize = compact ? 20.0 : 24.0;
        final gapIcon = compact ? 8.0 : 12.0;
        final gapTitle = compact ? 4.0 : 5.0;
        return _iconCaptionCard(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.backgroundBlue,
                ),
                child: SvgPicture.asset(
                  "assets/icons/schedule_icon.svg",
                  width: iconSize,
                  height: iconSize,
                  colorFilter: ColorFilter.mode(
                    AppColors.primaryBlue,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(height: gapIcon),
              Text('Расписание', style: _cardTitleStyleFor(context)),
              SizedBox(height: gapTitle),
              Text(
                count == 0 ? 'Нет пар' : '$count ${_pairWord(count)} сегодня',
                style: _cardSubtitleStyleFor(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onPressed: () => context.push('/app/schedule'),
        );
      },
    );
  }

  static String _pairWord(int n) {
    if (n == 1) return 'пара';
    if (n >= 2 && n <= 4) return 'пары';
    return 'пар';
  }
  Widget _taskButton(BuildContext context) {
    final compact = _compactHome(context);
    final iconPad = compact ? 8.0 : 10.0;
    final iconSize = compact ? 20.0 : 24.0;
    final gapIcon = compact ? 8.0 : 12.0;
    final gapTitle = compact ? 4.0 : 5.0;
    return _iconCaptionCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.backgroundGreen,
            ),
            child: SvgPicture.asset(
              'assets/icons/book_icon.svg',
              width: iconSize,
              height: iconSize,
              colorFilter: const ColorFilter.mode(AppColors.primaryGreen, BlendMode.srcIn),
            ),
          ),
          SizedBox(height: gapIcon),
          Text('Задания', style: _cardTitleStyleFor(context)),
          SizedBox(height: gapTitle),
          Text(
            '5 активных тем',
            style: _cardSubtitleStyleFor(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      onPressed: () => context.push('/app/tasks'),
    );
  }

  Widget _scheduleAndTasksSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppUi.spacingBetweenCards;
        final slotW = (constraints.maxWidth - gap) / 2;
        // Две колонки дают слишком узкую ячейку — вертикальная раскладка.
        final useColumn = slotW < 112 || constraints.maxWidth < 340;
        if (useColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _scheduleButton(context),
              SizedBox(height: gap),
              _taskButton(context),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _scheduleButton(context)),
              SizedBox(width: gap),
              Expanded(child: _taskButton(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _scheduleSection(BuildContext context) {
    final sectionTitleStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.0,
      color: AppColors.textPrimary,
    );
    return FutureBuilder<List<ScheduleLesson>>(
      future: _todayLessonsFuture,
      builder: (context, snap) {
        final items = snap.data ?? const <ScheduleLesson>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Расписание на сегодня', style: sectionTitleStyle),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text(
                'Нет пар',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.caption,
                ),
              )
            else
              ...items.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: AppUi.spacingBetweenCards),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ScheduleLessonTile(lesson: e),
                    ),
                  )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final padH = w < 360 ? 16.0 : AppUi.screenPaddingH;
    final padV = w < 360 ? 20.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 0,
        children: [
          FutureBuilder<_BannerData>(
            future: _bannerFuture,
            builder: (context, snap) {
              final data = snap.data;
              return HomeHeroBanner(
                fullName: _shortName(data?.me?.fullName),
                groupLabel: data?.group?.displayLabel,
                performanceLabel: data?.avgLabel,
              );
            },
          ),
          const SizedBox(height: AppUi.spacingAfterBanner),
          _scheduleAndTasksSection(context),
          const SizedBox(height: AppUi.spacingAfterButtons),
          _scheduleSection(context),
        ],
      ),
    );
  }
}

class _BannerData {
  const _BannerData({required this.me, required this.group, required this.avgLabel});
  final UserModel? me;
  final GroupModel? group;
  final String? avgLabel;
}

String _shortName(String? fullName) {
  final s = (fullName ?? '').trim();
  if (s.isEmpty) return '-';
  final parts = s.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty).toList();
  if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
  return parts.first;
}

Future<_BannerData> _loadBannerData() async {
  // В UI читаем из кэша (прогрев на splash). Сеть здесь не дергаем.
  UserModel? me;
  GroupModel? group;
  List<GradeEntity> grades = const <GradeEntity>[];
  try {
    me = await _loadMe();
  } catch (_) {}
  try {
    group = await _loadMyGroup();
  } catch (_) {}
  try {
    grades = await _loadGrades();
  } catch (_) {}

  final avg = _calcAverage(grades);
  final avgLabel = avg == null ? null : avg.toStringAsFixed(2);

  return _BannerData(me: me, group: group, avgLabel: avgLabel);
}

double? _calcAverage(List<GradeEntity> grades) {
  final nums = <double>[];
  for (final g in grades) {
    final raw = g.grade.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v != null) nums.add(v);
  }
  if (nums.isEmpty) return null;
  final sum = nums.fold<double>(0, (a, b) => a + b);
  return sum / nums.length;
}

Future<GroupModel?> _loadMyGroup() async {
  const cacheKey = 'groups:my';
  final cached = AppContainer.jsonCache.getJsonMap(cacheKey);
  if (cached == null) return null;
  return GroupModel.fromJson(cached);
}

Future<List<GradeEntity>> _loadGrades() async {
  const cacheKey = 'grades:my';
  final cached = AppContainer.jsonCache.getJsonList(cacheKey);
  if (cached == null) return const <GradeEntity>[];
  return cached
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .map((j) => GradeEntity(
            subjectName: (j['subject_name'] as String?) ?? '',
            grade: (j['grade'] as String?) ?? '',
            gradeType: (j['grade_type'] as String?),
            teacherName: (j['teacher_name'] as String?),
            date: DateTime.tryParse((j['date'] as String?) ?? ''),
          ))
      .toList();
}

Future<UserModel> _loadMe() async {
  const cacheKey = 'auth:me';
  final cached = AppContainer.jsonCache.getJsonMap(cacheKey);
  if (cached == null) throw StateError('no cached me');
  return UserModel.fromJson(cached);
}

Future<int> _loadTodayCount(int todayIndex) async {
  final lessons = await _loadWeekLessonsForDay(todayIndex);
  return lessons.length;
}

Future<List<ScheduleLesson>> _loadTodayLessons(int todayIndex) async {
  if (todayIndex != DateTime.now().weekday - 1) return const <ScheduleLesson>[];
  const cacheKey = 'schedule:today';
  try {
    final fresh = await AppContainer.scheduleApi.getToday();
    await AppContainer.jsonCache.setJson(
      cacheKey,
      [
        for (final l in fresh)
          {
            'weekday_index': l.weekdayIndex,
            'subject': l.subject,
            'time': l.time,
            'teacher': l.teacher,
            'auditorium': l.auditorium,
          }
      ],
    );
    // В текущем бэке /schedule/today может возвращать массив на неделю.
    return fresh.where((e) => e.weekdayIndex == todayIndex).toList();
  } catch (_) {
    final cached = AppContainer.jsonCache.getJsonList(cacheKey);
    if (cached == null) return const <ScheduleLesson>[];
    final all = cached
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(
          (j) => ScheduleLesson(
            weekdayIndex: j['weekday_index'] is int ? (j['weekday_index'] as int) : null,
            subject: (j['subject'] as String?) ?? '',
            time: (j['time'] as String?) ?? '',
            teacher: (j['teacher'] as String?) ?? '',
            auditorium: (j['auditorium'] as String?) ?? '',
          ),
        )
        .toList();
    return all.where((e) => e.weekdayIndex == todayIndex).toList();
  }
}

Future<List<ScheduleLesson>> _loadWeekLessonsForDay(int dayIndex) async {
  const cacheKey = 'schedule:week';
  try {
    final fresh = await AppContainer.scheduleApi.getWeek();
    await AppContainer.jsonCache.setJson(
      cacheKey,
      [
        for (final l in fresh)
          {
            'weekday_index': l.weekdayIndex,
            'subject': l.subject,
            'time': l.time,
            'teacher': l.teacher,
            'auditorium': l.auditorium,
          }
      ],
    );
    return fresh.where((e) => e.weekdayIndex == dayIndex).toList();
  } catch (_) {
    final cached = AppContainer.jsonCache.getJsonList(cacheKey);
    if (cached == null) return const <ScheduleLesson>[];
    final all = cached
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(
          (j) => ScheduleLesson(
            weekdayIndex: j['weekday_index'] is int ? (j['weekday_index'] as int) : null,
            subject: (j['subject'] as String?) ?? '',
            time: (j['time'] as String?) ?? '',
            teacher: (j['teacher'] as String?) ?? '',
            auditorium: (j['auditorium'] as String?) ?? '',
          ),
        )
        .toList();
    return all.where((e) => e.weekdayIndex == dayIndex).toList();
  }
}

