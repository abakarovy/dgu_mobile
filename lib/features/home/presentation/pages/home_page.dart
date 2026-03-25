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

  static const double _cardHeight = AppUi.homeCardHeight;
  static const EdgeInsets _cardPadding = AppUi.homeCardPadding;

  Widget _iconCaptionCard(Widget child, {VoidCallback? onPressed}) {
    return SizedBox(
      height: _cardHeight,
      child: ElevatedButton(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(_cardPadding),
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
      ),
    );
  }
  Widget _scheduleButton(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1;
    final count = scheduleLessonsForDay(todayIndex).length;
    return _iconCaptionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.backgroundBlue,
            ),
            child: SvgPicture.asset(
              "assets/icons/schedule_icon.svg",
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                AppColors.primaryBlue,
                BlendMode.srcIn
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text("Расписание", style: _cardTitleStyle(context)),
          const SizedBox(height: 5),
          Text(
            count == 0 ? 'Нет пар' : '$count ${_pairWord(count)} сегодня',
            style: _cardSubtitleStyle(context),
          )
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
    return _iconCaptionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.backgroundGreen,
            ),
            child: SvgPicture.asset(
              "assets/icons/book_icon.svg",
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(AppColors.primaryGreen, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 12),
          Text("Задания", style: _cardTitleStyle(context)),
          const SizedBox(height: 5),
          Text("5 активных тем", style: _cardSubtitleStyle(context))

        ],
      ),
      onPressed: () => context.push('/app/tasks'),
    );
  }
  Widget _scheduleAndTasksSection(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _scheduleButton(context)),
        const SizedBox(width: AppUi.spacingBetweenCards),
        Expanded(child: _taskButton(context)),
      ],
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
    return SingleChildScrollView(
      padding: AppUi.screenPaddingAll,
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

