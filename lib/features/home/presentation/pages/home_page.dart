import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../schedule/data/schedule_mock_data.dart';
import '../../../schedule/presentation/widgets/schedule_lesson_tile.dart';
import '../widgets/home_hero_banner.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

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
    final todayIndex = DateTime.now().weekday - 1;
    final count = scheduleLessonsForDay(todayIndex).length;
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
    final todayIndex = DateTime.now().weekday - 1;
    final items = scheduleLessonsForDay(todayIndex);
    final sectionTitleStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.0,
      color: AppColors.textPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Расписание на сегодня', style: sectionTitleStyle),
        const SizedBox(height: 16),
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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 0,
        children: [
          const HomeHeroBanner(),
          const SizedBox(height: AppUi.spacingAfterBanner),
          _scheduleAndTasksSection(context),
          const SizedBox(height: AppUi.spacingAfterButtons),
          _scheduleSection(context),
        ],
      ),
    );
  }
}

