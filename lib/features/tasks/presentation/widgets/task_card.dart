import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/task_item.dart';

/// Карточка одного задания: чип предмета, название, срок с иконкой часов.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final TaskItem task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUi.radiusS),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: AppUi.taskChipPadding,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlue,
                    borderRadius: BorderRadius.circular(AppUi.taskChipRadius),
                  ),
                  child: Text(
                    task.subjectName.toUpperCase(),
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 8,
                      height: 12 / 8,
                      letterSpacing: 0.4,
                      color: AppColors.taskChipText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/clock.svg',
                    width: 12,
                    height: 12,
                    colorFilter: const ColorFilter.mode(
                      AppColors.notificationSubtitle,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.deadlineText,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                      height: 15 / 10,
                      color: AppColors.taskDeadline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
