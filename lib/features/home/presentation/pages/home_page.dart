import 'dart:async';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../schedule/data/schedule_lesson.dart';
import '../../../schedule/domain/schedule_calendar_filter.dart';
import '../../../schedule/presentation/widgets/schedule_lesson_tile.dart';
import '../../../../core/di/app_container.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/one_c_my_profile.dart';
import '../../../../data/models/user_model.dart';
import '../../../grades/domain/entities/grade_entity.dart';
import '../widgets/home_hero_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late _BannerData _banner;
  List<ScheduleLesson> _todayLessons = const <ScheduleLesson>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _banner = _readBannerData();
    _hydrateTodayFromCache();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _banner = _readBannerData());
      unawaited(_refreshTodayScheduleSilent());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _hydrateTodayFromCache();
      if (mounted) setState(() => _banner = _readBannerData());
      unawaited(_refreshTodayScheduleSilent());
    }
  }

  void _hydrateTodayFromCache() {
    var list = _mapCacheToLessons(AppContainer.jsonCache.getJsonList('schedule:week:v2'));
    if (list.isEmpty) {
      list = _mapCacheToLessons(AppContainer.jsonCache.getJsonList('schedule:today'));
    }
    final filtered = filterScheduleForCalendarToday(list);
    if (!mounted) return;
    setState(() => _todayLessons = filtered);
  }

  List<ScheduleLesson> _mapCacheToLessons(List<dynamic>? cached) {
    if (cached == null) return const <ScheduleLesson>[];
    return cached
        .whereType<Map>()
        .map((m) => ScheduleLesson.fromJsonMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _refreshTodayScheduleSilent() async {
    try {
      final fresh =
          await AppContainer.scheduleApi.getWeekForCalendar(DateTime.now());
      await AppContainer.jsonCache.setJson(
        'schedule:week:v2',
        [for (final l in fresh) l.toJsonMap()],
      );
      final shown = filterScheduleForCalendarToday(fresh);
      await AppContainer.jsonCache.setJson(
        'schedule:today',
        [for (final l in shown) l.toJsonMap()],
      );
      if (!mounted) return;
      setState(() => _todayLessons = shown);
    } catch (_) {}
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
    final count = _todayLessons.length;
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
    final items = _todayLessons;
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
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final padH = w < 360 ? 16.0 : AppUi.screenPaddingH;
    final padV = w < 360 ? 20.0 : 24.0;
    return RefreshIndicator(
      onRefresh: () async {
        _hydrateTodayFromCache();
        await _refreshTodayScheduleSilent();
        if (mounted) setState(() => _banner = _readBannerData());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 0,
        children: [
          HomeHeroBanner(
            fullName: _shortName(_banner.me?.fullName),
            groupLabel: _banner.groupLabel,
            performanceLabel: _banner.avgLabel,
          ),
          const SizedBox(height: AppUi.spacingAfterBanner),
          _scheduleAndTasksSection(context),
          const SizedBox(height: AppUi.spacingAfterButtons),
          _scheduleSection(context),
        ],
      ),
      ),
    );
  }
}

class _BannerData {
  const _BannerData({required this.me, this.groupLabel, this.avgLabel});
  final UserModel? me;
  final String? groupLabel;
  final String? avgLabel;
}

String _shortName(String? fullName) {
  final s = (fullName ?? '').trim();
  if (s.isEmpty) return '-';
  final parts = s.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty).toList();
  if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
  return parts.first;
}

/// Баннер читает только кэш (прогрев на splash). Группа: `1c:my-profile`, иначе `groups:my`.
_BannerData _readBannerData() {
  UserModel? me;
  try {
    final c = AppContainer.jsonCache.getJsonMap('auth:me');
    if (c != null) me = UserModel.fromJson(c);
  } catch (_) {}

  GroupModel? group;
  try {
    final c = AppContainer.jsonCache.getJsonMap('groups:my');
    if (c != null) group = GroupModel.fromJson(c);
  } catch (_) {}

  OneCMyProfile? oneC;
  try {
    final o = AppContainer.jsonCache.getJsonMap('1c:my-profile');
    oneC = o != null ? OneCMyProfile.fromJson(o) : null;
  } catch (_) {}

  final grades = _loadGradesFromCache();
  final avg = _calcAverage(grades);
  final avgLabel = avg?.toStringAsFixed(2);

  return _BannerData(
    me: me,
    groupLabel: OneCMyProfile.resolveGroupLabel(
      groupFrom1c: oneC?.group,
      groupFromApi: group?.displayLabel,
    ),
    avgLabel: avgLabel,
  );
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

List<GradeEntity> _loadGradesFromCache() {
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

