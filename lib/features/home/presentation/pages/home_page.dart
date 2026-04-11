import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../schedule/data/schedule_lesson.dart';
import '../../../schedule/domain/schedule_calendar_filter.dart';
import '../../../schedule/presentation/widgets/schedule_lesson_tile.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/navigation/home_refresh_host.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/one_c_my_profile.dart';
import '../../../../data/models/user_model.dart';
import '../../../grades/domain/entities/grade_entity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Duration _silentScheduleMinInterval = Duration(minutes: 8);
  static const double _uiScaleBoost = 1.2;

  late _BannerData _banner;
  List<ScheduleLesson> _todayLessons = const <ScheduleLesson>[];
  DateTime? _lastSilentScheduleRefreshAt;

  @override
  void initState() {
    super.initState();
    _banner = _readBannerData();
    _hydrateTodayFromCache();
    HomeRefreshHost.register(({required bool force}) {
      if (!mounted) return;
      _hydrateTodayFromCache();
      unawaited(_refreshTodayScheduleSilent(force: force));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _banner = _readBannerData());
      unawaited(_refreshTodayScheduleSilent(force: false));
    });
  }

  @override
  void dispose() {
    HomeRefreshHost.clear();
    super.dispose();
  }

  void _hydrateTodayFromCache() {
    // Родитель: расписание берём из `/api/parents/student-data` (кэш), а не из `schedule:*`.
    final isParent = _banner.me?.role.trim().toLowerCase() == 'parent';
    if (isParent) {
      final sd = AppContainer.jsonCache.getJsonMap('parents:student-data');
      final mapped = _mapParentStudentDataToLessons(sd);
      if (!mounted) return;
      setState(() => _todayLessons = filterScheduleForCalendarToday(mapped));
      return;
    }

    var list = _mapCacheToLessons(AppContainer.jsonCache.getJsonList('schedule:week:v2'));
    if (list.isEmpty) {
      list = _mapCacheToLessons(AppContainer.jsonCache.getJsonList('schedule:today'));
    }
    final filtered = filterScheduleForCalendarToday(list);
    if (!mounted) return;
    setState(() => _todayLessons = filtered);
  }

  List<ScheduleLesson> _mapParentStudentDataToLessons(Map<String, dynamic>? data) {
    if (data == null) return const <ScheduleLesson>[];
    dynamic rawSchedule = data['schedule'];
    if (rawSchedule is Map) rawSchedule = rawSchedule['schedule'];
    if (rawSchedule is! List) return const <ScheduleLesson>[];

    String? toYmd(String ddMmYyyy) {
      final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(ddMmYyyy.trim());
      if (m == null) return null;
      final dd = m.group(1)!;
      final mm = m.group(2)!;
      final yy = m.group(3)!;
      return '$yy-$mm-$dd';
    }

    final out = <ScheduleLesson>[];
    for (final e in rawSchedule) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final date = (m['date'] ?? '').toString();
      final ymd = toYmd(date);
      final map = <String, dynamic>{
        'lesson_date': ymd,
        'pair_number': m['pair_number'],
        'subject': (m['subject'] ?? '').toString(),
        'time': (m['time'] ?? '').toString(),
        'teacher': (m['teacher'] ?? '').toString(),
        'auditorium': (m['auditorium'] ?? m['room'] ?? '').toString(),
      };
      out.add(ScheduleLesson.fromJsonMap(map));
    }
    return out;
  }

  List<ScheduleLesson> _mapCacheToLessons(List<dynamic>? cached) {
    if (cached == null) return const <ScheduleLesson>[];
    return cached
        .whereType<Map>()
        .map((m) => ScheduleLesson.fromJsonMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _refreshTodayScheduleSilent({required bool force}) async {
    final isParent = _banner.me?.role.trim().toLowerCase() == 'parent';
    if (isParent) {
      try {
        final data = await AppContainer.accountApi
            .getParentsStudentData()
            .timeout(ApiConstants.prefetchRequestTimeout);
        await AppContainer.jsonCache.setJson('parents:student-data', data);
        if (!mounted) return;
        setState(() {
          _banner = _readBannerData();
        });
        _hydrateTodayFromCache();
      } catch (_) {}
      return;
    }

    if (!force) {
      final cached = _mapCacheToLessons(AppContainer.jsonCache.getJsonList('schedule:week:v2'));
      final hasWeek = cached.isNotEmpty;
      final last = _lastSilentScheduleRefreshAt;
      if (hasWeek &&
          last != null &&
          DateTime.now().difference(last) < _silentScheduleMinInterval) {
        return;
      }
    }
    try {
      final fresh = await AppContainer.scheduleApi
          .getWeekForCalendar(DateTime.now(), forceRefresh: force);
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
      _lastSilentScheduleRefreshAt = DateTime.now();
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
    final activeCount = _readActiveAssignmentsCount();
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
            activeCount == null ? '—' : '$activeCount активных',
            style: _cardSubtitleStyleFor(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      onPressed: () => context.push('/app/tasks'),
    );
  }

  /// Минимальная ширина карточки действия, чтобы подпись помещалась в одну строку.
  double _minActionCardWidth(
    BuildContext context,
    double sf,
    String label,
    double labelFontSize,
  ) {
    final style = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: labelFontSize * sf,
      color: AppColors.textPrimary,
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final horizPad = 12 * sf * 2;
    final iconW = 35 * sf;
    final gap = 10 * sf;
    return horizPad + iconW + gap + tp.width;
  }

  int? _readActiveAssignmentsCount() {
    try {
      final list = AppContainer.jsonCache.getJsonList('mobile:assignments:my');
      if (list == null) return null;
      var active = 0;
      for (final e in list) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final v = m['is_done'] ?? m['done'] ?? m['completed'];
        final done = (v is bool)
            ? v
            : (v is num)
                ? v != 0
                : (v is String)
                    ? (v.trim().toLowerCase() == 'true' || v.trim() == '1')
                    : false;
        if (!done) active++;
      }
      return active;
    } catch (_) {
      return null;
    }
  }

  // ignore: unused_element
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

  // ignore: unused_element
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
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Padding(
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
                child: ScheduleLessonTile(
                  lesson: e,
                  layoutScale: ScheduleLessonTile.layoutScaleOf(context),
                  showBottomDivider: i < items.length - 1,
                  isFirstInList: i == 0,
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sf = min(
      MediaQuery.sizeOf(context).width / 402,
      MediaQuery.sizeOf(context).height / 874,
    ) * _uiScaleBoost;
    return ColoredBox(
      color: Colors.white,
      child: RefreshIndicator(
        onRefresh: () async {
          _hydrateTodayFromCache();
          await _refreshTodayScheduleSilent(force: true);
          if (mounted) setState(() => _banner = _readBannerData());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 0,
            children: [
              _buildMainGradientCard(context),
              SizedBox(height: 12 * min(
                MediaQuery.sizeOf(context).width / 402,
                MediaQuery.sizeOf(context).height / 874,
              )),
              _actionsSection(sf: sf),
              SizedBox(height: 40 * sf),
              _todayLessonsSection(sf: sf),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainGradientCard(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Масштабируемся от фига 402x874.
    final sf = min(size.width / 402, size.height / 874) * _uiScaleBoost;

    final radius = 20.0 * sf;
    final pad = 20.0 * sf;

    final dateNow = DateTime.now();
    final summary = _buildTodaySummary(dateNow);
    final isParent = (_banner.me?.role ?? '').trim().toLowerCase() == 'parent';
    final studentName = _banner.studentFullName ?? _banner.me?.fullName;
    final displayName = isParent
        ? _displayName(_toGenitiveForParent(studentName))
        : _displayName(_banner.me?.fullName);

    final groupParsed = _parseGroupForHome(_banner.groupLabel);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          // Приближение к 100.35deg.
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E40AF),
            Color(0xFF3B82F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDBEAFE),
            offset: Offset(0, 5.12 * sf),
            blurRadius: 6.4 * sf,
            spreadRadius: -3.84 * sf,
          ),
          BoxShadow(
            color: const Color(0xFFDBEAFE),
            offset: Offset(0, 12.8 * sf),
            blurRadius: 16 * sf,
            spreadRadius: -3.2 * sf,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isParent) ...[
                  _roleChip(sf: sf, text: 'Родитель'),
                  SizedBox(height: 10 * sf),
                ],
                Text(
                  displayName,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 19.19 * sf,
                    height: 23.03 / 19.19,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6 * sf),
                Text(
                  isParent ? _buildTodaySummary(dateNow, parentStudent: displayName) : summary,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 10.24 * sf,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 30 * sf),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isParent) ...[
                      _groupRightChip(sf: sf, text: groupParsed.courseGroupText),
                      SizedBox(width: 10 * sf),
                      _groupRightChip(sf: sf, text: groupParsed.groupAbbr),
                    ] else ...[
                      _courseChip(sf: sf, text: groupParsed.courseGroupText),
                      SizedBox(width: 10 * sf),
                      _groupRightChip(sf: sf, text: groupParsed.groupAbbr),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // `image_home.png` прижата справа и не зависит от внутренних паддингов.
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/image_home.png',
              width: 108 * sf,
              height: 123 * sf,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseChip({required double sf, required String text}) {
    // Белый контейнер: h=28, paddingX=15, radius=8, shadow лёгкая.
    final blueText = const Color.fromRGBO(29, 78, 216, 1);
    return Container(
      height: 28 * sf,
      padding: EdgeInsets.symmetric(horizontal: 15 * sf),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * sf),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 0.64 * sf),
            blurRadius: 1.28 * sf,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 8.96 * sf,
            color: blueText,
          ),
        ),
      ),
    );
  }

  Widget _roleChip({required double sf, required String text}) {
    return Container(
      height: 22 * sf,
      padding: EdgeInsets.symmetric(horizontal: 15 * sf),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * sf),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTextStyle.inter(
          fontWeight: FontWeight.w700,
          fontSize: 12 * sf,
          height: 1.0,
          color: const Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _groupRightChip({required double sf, required String text}) {
    final outerR = 8 * sf;
    final outerH = 28 * sf;
    final borderW = 0.64 * sf;
    final borderColor = Colors.white.withValues(alpha: 0.2);
    final bg = const Color.fromRGBO(59, 130, 246, 0.3);
    final iconFont = 8.96 * sf;

    return ClipRRect(
      borderRadius: BorderRadius.circular(outerR),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7.6778 * sf, sigmaY: 7.6778 * sf),
        child: Container(
          height: outerH,
          padding: EdgeInsets.symmetric(horizontal: 15 * sf),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(outerR),
            border: Border.all(color: borderColor, width: borderW),
          ),
          child: Center(
            child: Text(
              text,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: iconFont,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionsSection({required double sf}) {
    // «Мои задания» и «Расписание»: в ряд пополам, пока обе подписи помещаются
    // в одну строку в своей половине; иначе — колонка на всю ширину.
    const labelFont = 11.72;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12 * sf;
        final minTasks = _minActionCardWidth(context, sf, 'Мои задания', labelFont);
        final minSchedule = _minActionCardWidth(context, sf, 'Расписание', labelFont);
        // Половины равны: каждая должна вместить свою самую длинную подпись в одну строку.
        final minHalf = max(minTasks, minSchedule);
        final minRowTotal = 2 * minHalf + gap;

        if (constraints.maxWidth < minRowTotal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tasksCard(context, sf: sf),
              SizedBox(height: gap),
              _scheduleCard(context, sf: sf),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _tasksCard(context, sf: sf)),
            SizedBox(width: gap),
            Expanded(child: _scheduleCard(context, sf: sf)),
          ],
        );
      },
    );
  }

  Widget _tasksCard(BuildContext context, {required double sf}) {
    // Точный цвет из дизайна: #10B98121 (alpha 0x21).
    final greenBg = const Color(0x2110B981);
    final iconBg = const Color(0xFFECFDF5);
    final iconColor = const Color.fromRGBO(5, 150, 105, 1);

    return _homeActionCard(
      sf: sf,
      background: greenBg,
      withShadow: true,
      iconBg: iconBg,
      iconColor: iconColor,
      iconAsset: 'assets/icons/book_icon.svg',
      iconW: 14.749685287475586,
      iconH: 18.437108993530273,
      label: 'Мои задания',
      labelColor: iconColor,
      labelFontSize: 11.72,
      onPressed: () => context.push('/app/tasks'),
    );
  }

  Widget _scheduleCard(BuildContext context, {required double sf}) {
    final iconBg = const Color.fromRGBO(46, 99, 213, 0.1);
    final iconColor = const Color.fromRGBO(37, 99, 235, 1);

    return _homeActionCard(
      sf: sf,
      background: const Color.fromRGBO(255, 255, 255, 1),
      withShadow: true,
      iconBg: iconBg,
      iconColor: iconColor,
      iconAsset: 'assets/icons/schedule_icon.svg',
      iconW: 13.500144958496094,
      iconH: 15,
      label: 'Расписание',
      labelColor: iconColor,
      labelFontSize: 11.72,
      onPressed: () => context.push('/app/schedule'),
    );
  }

  Widget _homeActionCard({
    required double sf,
    required Color background,
    required bool withShadow,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required double labelFontSize,
    required String iconAsset,
    required double iconW,
    required double iconH,
    required VoidCallback onPressed,
  }) {
    final radius = 20 * sf;

    final card = Container(
      height: 90 * sf,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.all(12 * sf),
      child: Align(
        alignment: Alignment.topLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 35 * sf,
              height: 35 * sf,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8 * sf),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconAsset,
                  width: iconW * sf,
                  height: iconH * sf,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ),
            SizedBox(width: 10 * sf),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: labelFontSize * sf,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final shadowLayer = Container(
      height: 90 * sf,
      decoration: BoxDecoration(
        color: Colors.white, // блокируем просвет тени через альфу
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(2.58 * sf, 3.32 * sf),
            blurRadius: 6.01 * sf,
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: withShadow
          ? Stack(
              children: [
                shadowLayer,
                card,
              ],
            )
          : card,
    );
  }

  Widget _todayLessonsSection({required double sf}) {
    final items = _todayLessons;
    if (items.isEmpty) {
      return SizedBox(
        height: 220 * sf,
        child: Center(
          child: Text(
            'Пар нет',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16 * sf,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      );
    }
    final gap = 12 * sf;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _todayLessonCard(sf: sf, lesson: items[i], index: i),
          if (i != items.length - 1) SizedBox(height: gap),
        ],
      ],
    );
  }

  Widget _todayLessonCard({
    required double sf,
    required ScheduleLesson lesson,
    required int index,
  }) {
    final h = 63 * sf;
    final r = 15 * sf;
    final padV = 14 * sf;
    final padH = 25 * sf;

    final ongoing = _isLessonOngoingNow(lesson);

    final bg = ongoing ? const Color(0x142563EB) : Colors.transparent;
    final border = ongoing
        ? Border(
            left: BorderSide(
              width: 3.63 * sf,
              color: const Color(0xFF2563EB),
            ),
          )
        : null;

    final start = _parseStartTime(lesson.time) ?? '—';
    final pairLabel = lesson.pairNumber != null
        ? (lesson.pairNumber == 0
            ? '0 ПАРА'
            : '${lesson.pairNumber} ПАРА'.toUpperCase())
        : '${index + 1} ПАРА';

    final timeColor = ongoing ? const Color(0xFF1E293B) : const Color(0xFF94A3B8);
    final pairColor = ongoing ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final subject = lesson.subject.trim();
    final teacher = lesson.teacher.trim();
    final aud = lesson.auditorium.trim();
    final teacherShort = _shortTeacherName(teacher);
    final details = <String>[
      if (teacherShort.isNotEmpty) 'Преп: $teacherShort',
      if (aud.isNotEmpty) 'Ауд: $aud',
    ].join(' • ');

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(r),
        border: border,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              children: [
                SizedBox(
                  width: 62 * sf,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        start,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.7 * sf,
                          height: 18.14 / 12.7,
                          color: timeColor,
                        ),
                      ),
                      Text(
                        pairLabel,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w400,
                          fontSize: 9.07 * sf,
                          height: 13.6 / 9.07,
                          letterSpacing: 0,
                          color: pairColor,
                        ).copyWith(
                          // keep "uppercase" look as requested
                          // (label already generated in uppercase)
                        ),
                      ),
                    ],
                  ),
                ),
                // Gap between time column and subject should be tighter.
                SizedBox(width: 6 * sf),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          subject.isEmpty ? '—' : subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false,
                          ),
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.7 * sf,
                            height: 1.0,
                            color: const Color(0xFF000000),
                          ),
                        ),
                      ),
                      if (details.isNotEmpty) ...[
                        Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false,
                          ),
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w400,
                            fontSize: 10.88 * sf,
                            height: 1.0,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Badge is positioned on the left-bottom corner.
              ],
            ),
          ),
          if (ongoing)
            Positioned(
              left: 6 * sf,
              bottom: 3 * sf,
              child: Container(
                width: 34 * sf,
                height: 12 * sf,
                decoration: BoxDecoration(
                  color: const Color(0x332B5ED0),
                  borderRadius: BorderRadius.circular(6 * sf),
                ),
                alignment: Alignment.center,
                child: Text(
                  'ИДЕТ',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 5.0 * sf,
                    color: const Color(0xFF2B5ED0),
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isLessonOngoingNow(ScheduleLesson lesson) {
    final range = _parseTimeRange(lesson.time);
    if (range == null) return false;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, range.$1.$1, range.$1.$2);
    final end = DateTime(now.year, now.month, now.day, range.$2.$1, range.$2.$2);
    return now.isAfter(start) && now.isBefore(end);
  }

  ((int, int), (int, int))? _parseTimeRange(String raw) {
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})').firstMatch(raw);
    if (m == null) return null;
    final sh = int.tryParse(m.group(1) ?? '');
    final sm = int.tryParse(m.group(2) ?? '');
    final eh = int.tryParse(m.group(3) ?? '');
    final em = int.tryParse(m.group(4) ?? '');
    if (sh == null || sm == null || eh == null || em == null) return null;
    return ((sh, sm), (eh, em));
  }

  String _shortTeacherName(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    return ScheduleLessonTile.abbreviateTeacherName(s);
  }

  String _buildTodaySummary(DateTime d, {String? parentStudent}) {
    final weekday = _ruWeekday(d.weekday);
    final month = _ruMonthGen(d.month);
    final day = d.day;

    final count = _todayLessons.length;
    if (count == 0) {
      if (parentStudent != null && parentStudent.trim().isNotEmpty) {
        return 'Сегодня $weekday, $day $month. У $parentStudent на сегодня нет пар.';
      }
      return 'Сегодня $weekday, $day $month. На сегодня нет пар.';
    }

    final firstTime = _parseStartTime(_todayLessons.first.time) ?? '—';
    if (parentStudent != null && parentStudent.trim().isNotEmpty) {
      return 'Сегодня $weekday, $day $month. У $parentStudent запланировано $count пар. Первая начнется в $firstTime.';
    }
    return 'Сегодня $weekday, $day $month. У вас запланировано $count пар. Первая начнется в $firstTime.';
  }

  String _toGenitiveForParent(String? fullName) {
    final s = (fullName ?? '').trim();
    if (s.isEmpty) return '';
    final parts = s.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return s;
    final last = parts[0];
    final first = parts.length > 1 ? parts[1] : '';
    final lastGen = _lastNameToGenitive(last);
    return [lastGen, first].where((x) => x.trim().isNotEmpty).join(' ');
  }

  String _lastNameToGenitive(String lastName) {
    final src = lastName.trim();
    if (src.isEmpty) return src;
    final lower = src.toLowerCase();
    String out;
    if (lower.endsWith('ев') || lower.endsWith('ёв') || lower.endsWith('ов') || lower.endsWith('ин')) {
      out = '$srcа';
    } else if (lower.endsWith('ий')) {
      out = '${src.substring(0, src.length - 2)}ия';
    } else if (lower.endsWith('ый') || lower.endsWith('ой')) {
      out = '${src.substring(0, src.length - 2)}ого';
    } else if (lower.endsWith('а')) {
      out = '${src.substring(0, src.length - 1)}ы';
    } else if (lower.endsWith('я')) {
      out = '${src.substring(0, src.length - 1)}и';
    } else {
      out = '$srcа';
    }
    // Preserve original casing similar to other UI ("Ягияев" => "Ягияева").
    final cap = _capWord(out);
    // If original was uppercase, keep uppercase.
    final isUpper = src == src.toUpperCase();
    return isUpper ? cap.toUpperCase() : cap;
  }

  String _ruWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'понедельник';
      case DateTime.tuesday:
        return 'вторник';
      case DateTime.wednesday:
        return 'среда';
      case DateTime.thursday:
        return 'четверг';
      case DateTime.friday:
        return 'пятница';
      case DateTime.saturday:
        return 'суббота';
      case DateTime.sunday:
        return 'воскресенье';
      default:
        return '';
    }
  }

  String _ruMonthGen(int month) {
    switch (month) {
      case 1:
        return 'января';
      case 2:
        return 'февраля';
      case 3:
        return 'марта';
      case 4:
        return 'апреля';
      case 5:
        return 'мая';
      case 6:
        return 'июня';
      case 7:
        return 'июля';
      case 8:
        return 'августа';
      case 9:
        return 'сентября';
      case 10:
        return 'октября';
      case 11:
        return 'ноября';
      case 12:
        return 'декабря';
      default:
        return '';
    }
  }

  String? _parseStartTime(String? time) {
    if (time == null) return null;
    final m = RegExp(r'(\d{2}:\d{2})').firstMatch(time);
    return m?.group(1);
  }

  String _displayName(String? fullName) {
    final s = (fullName ?? '').trim();
    if (s.isEmpty) return '-';
    final parts = s.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty).toList();
    final last = parts.isNotEmpty ? parts[0] : '';
    final first = parts.length > 1 ? parts[1] : '';
    return '${_capWord(last)} ${_capWord(first)}'.trim();
  }

  String _capWord(String w) {
    final t = w.trim();
    if (t.isEmpty) return t;
    final rest = t.length > 1 ? t.substring(1).toLowerCase() : '';
    return t[0].toUpperCase() + rest;
  }

  _GroupHomeParsed _parseGroupForHome(String? groupLabel) {
    final raw = (groupLabel ?? '').trim();
    if (raw.isEmpty) {
      return _GroupHomeParsed(groupAbbr: '-', courseGroupText: '-');
    }

    // Пример: «ИСиП 4к 1г 2022»
    final groupAbbr = raw.split(RegExp(r'\s+')).first;

    final courseM = RegExp(r'(\d+)\s*к').firstMatch(raw);
    final groupM = RegExp(r'(\d+)\s*г').firstMatch(raw);
    final course = courseM?.group(1);
    final groupNum = groupM?.group(1);

    final courseGroupText = (course != null && groupNum != null)
        ? '$course курс $groupNum группа'
        : raw;

    return _GroupHomeParsed(groupAbbr: groupAbbr, courseGroupText: courseGroupText);
  }
}

class _GroupHomeParsed {
  const _GroupHomeParsed({required this.groupAbbr, required this.courseGroupText});
  final String groupAbbr;
  final String courseGroupText;
}

class _BannerData {
  const _BannerData({
    required this.me,
    this.studentFullName,
    this.groupLabel,
    this.avgLabel,
  });
  final UserModel? me;
  final String? studentFullName;
  final String? groupLabel;
  final String? avgLabel;
}

/// Баннер читает только кэш (прогрев на splash). Группа: `1c:my-profile`, иначе `groups:my`.
_BannerData _readBannerData() {
  UserModel? me;
  try {
    final c = AppContainer.jsonCache.getJsonMap('auth:me');
    if (c != null) me = UserModel.fromJson(c);
  } catch (_) {}

  // Родитель: имя/группа берутся из `/api/parents/student-data` (кэш).
  String? parentStudentFullName;
  OneCMyProfile? parentOneC;
  try {
    if ((me?.role ?? '').trim().toLowerCase() == 'parent') {
      final sd = AppContainer.jsonCache.getJsonMap('parents:student-data');
      if (sd != null) {
        final student = sd['student'];
        if (student is Map) {
          final fn = (student['full_name'] ?? '').toString().trim();
          if (fn.isNotEmpty) parentStudentFullName = fn;
        }
        final p1c = sd['profile_1c'];
        if (p1c is Map) {
          parentOneC = OneCMyProfile.fromJson(Map<String, dynamic>.from(p1c));
        }
      }
    }
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
  final currentSem = _currentSemesterLabel(grades);
  final avg = _calcAverage(grades, semester: currentSem);
  final avgLabel = avg?.toStringAsFixed(2);

  return _BannerData(
    me: me,
    studentFullName: parentStudentFullName,
    groupLabel: OneCMyProfile.resolveGroupLabel(
      groupFrom1c: (parentOneC ?? oneC)?.group,
      groupFromApi: group?.displayLabel,
    ),
    avgLabel: avgLabel,
  );
}

double? _calcAverage(List<GradeEntity> grades, {required String? semester}) {
  final nums = <double>[];
  for (final g in grades) {
    if (semester != null && g.semester?.trim() != semester) continue;
    final raw = g.grade.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v != null) nums.add(v);
  }
  if (nums.isEmpty) return null;
  final sum = nums.fold<double>(0, (a, b) => a + b);
  return sum / nums.length;
}

String? _currentSemesterLabel(List<GradeEntity> grades) {
  int? bestKey;
  String? bestLabel;

  int? keyOf(String? s) {
    if (s == null) return null;
    final t = s.trim();
    final re = RegExp(r'([12])\s*сем\s*(\d{4})-(\d{4})');
    final m = re.firstMatch(t);
    if (m == null) return null;
    final sem = int.tryParse(m.group(1) ?? '');
    final y1 = int.tryParse(m.group(2) ?? '');
    final y2 = int.tryParse(m.group(3) ?? '');
    if (sem == null || y1 == null || y2 == null) return null;
    return (y2 * 10) + sem; // достаточно для сравнения "новизны"
  }

  for (final g in grades) {
    final k = keyOf(g.semester);
    if (k == null) continue;
    if (bestKey == null || k > bestKey) {
      bestKey = k;
      bestLabel = g.semester?.trim();
    }
  }
  return bestLabel;
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
            semester: (j['semester'] as String?),
          ))
      .toList();
}

