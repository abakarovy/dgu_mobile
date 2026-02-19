import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/shared/widgets/shallow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../widgets/home_hero_banner.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

  Widget _iconCaptionCard(Widget child) {
    return Expanded(
      child: ElevatedButton(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.all(20)),
          alignment: AlignmentGeometry.centerLeft,
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(110)),
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
  Widget _scheduleButton() {
    return _iconCaptionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsetsGeometry.all(10),
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
          Text("Расписание", style: TextStyle(fontSize: 16),),
          Text("3 пары сегодня", style: TextStyle(fontSize: 10, color: AppColors.caption),)
        ],
      ),
    );
  }
  Widget _taskButton() {
    return _iconCaptionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsetsGeometry.all(10),
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
          Text("Задания", style: TextStyle(fontSize: 16, color: AppColors.primaryGreen),),
          Text("5 активных тем", style: TextStyle(fontSize: 10, color: AppColors.caption),)

        ],
      ),
    );
  }
  Widget _scheduleAndTasksSection() {
    return IntrinsicHeight(
      child: Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _scheduleButton(),
          _taskButton(),
        ],
      ),
    );
  }

  Widget _scheduleSection(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final items = [
      _ScheduleItem(subject: 'Веб разработка', time: '8:30', teacher: 'Алиева А.М.'),
      _ScheduleItem(subject: 'Базы данных', time: '10:10', teacher: 'Иванов И.И.'),
      _ScheduleItem(subject: 'Математика', time: '12:00', teacher: 'Петрова П.П.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Расписание', style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ShallowButton(label: "Все", onPressed: () {},)
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          const HomeHeroBanner(),
          _scheduleAndTasksSection(),
          const SizedBox(height: 8),
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
  });
  final String subject;
  final String time;
  final String teacher;
}

class _ScheduleItemTile extends StatelessWidget {
  const _ScheduleItemTile({required this.item});

  final _ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.subject, style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${item.time} • ${item.teacher}',
              style: theme.bodySmall?.copyWith(color: AppColors.caption),
            ),
          ],
        ),
      ],
    );
  }
}
