import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/shared/widgets/shallow_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/home_hero_banner.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

  static TextStyle _cardTitleStyle(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.0,
    color: AppColors.textPrimary,
  );

  static TextStyle _cardSubtitleStyle(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 10,
    height: 1.0,
    color: AppColors.caption,
  );

  static const double _cardHeight = 122;
  static const EdgeInsets _cardPadding = EdgeInsets.all(17);

  Widget _iconCaptionCard(Widget child) {
    return SizedBox(
      height: _cardHeight,
      child: ElevatedButton(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(_cardPadding),
          alignment: AlignmentGeometry.centerLeft,
          minimumSize: const WidgetStatePropertyAll(Size.zero),
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        onPressed: () {},
        child: child,
      ),
    );
  }
  Widget _scheduleButton(BuildContext context) {
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
          Text("3 пары сегодня", style: _cardSubtitleStyle(context))
        ],
      ),
    );
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
    );
  }
  Widget _scheduleAndTasksSection(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _scheduleButton(context)),
        const SizedBox(width: 16),
        Expanded(child: _taskButton(context)),
      ],
    );
  }

  Widget _scheduleSection(BuildContext context) {
    final items = [
      _ScheduleItem(subject: 'Веб разработка', time: '8:30', teacher: 'Алиева А.М.', auditorium: "каб. 201"),
      _ScheduleItem(subject: 'Базы данных', time: '10:10', teacher: 'Иванов И.И.', auditorium: "каб. 201"),
      _ScheduleItem(subject: 'Математика', time: '12:00', teacher: 'Петрова П.П.', auditorium: "каб. 201"),
    ];
    final sectionTitleStyle = GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.0,
      color: AppColors.textPrimary,
    );
    final allButtonStyle = GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1.0,
      color: AppColors.primaryBlue,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Расписание на сегодня', style: sectionTitleStyle),
            ShallowButton(
              label: 'Все',
              style: allButtonStyle,
              onPressed: () => context.push('/app/schedule'),
            )
          ],
        ),
        ...items.map((e) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), offset: Offset(0, 2))]
          ),
          padding: const EdgeInsets.all(12),
          child: 
            _ScheduleItemTile(item: e),
          )
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 0,
        children: [
          const HomeHeroBanner(),
          const SizedBox(height: 22),
          _scheduleAndTasksSection(context),
          const SizedBox(height: 24),
          _scheduleSection(context),
        ],
      ),
    );
  }
}

class _ScheduleItem {
  const _ScheduleItem({
    required this.subject,
    required this.time,
    required this.teacher,
    required this.auditorium
  });
  final String subject;
  final String time;
  final String teacher;
  final String auditorium;
}

class _ScheduleItemTile extends StatelessWidget {
  const _ScheduleItemTile({required this.item});

  final _ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final subjectStyle = GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 1.0,
      color: AppColors.textPrimary,
    );
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.subject, style: subjectStyle),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${item.time} • ${item.teacher}',
              style: theme.bodySmall?.copyWith(color: AppColors.caption),
            ),
            Text(
              item.auditorium,
              style: theme.bodySmall?.copyWith(color: AppColors.caption),
            ),
          ],
        ),
      ],
    );
  }
}
