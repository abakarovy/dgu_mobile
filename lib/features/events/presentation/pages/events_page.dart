import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Вкладка «Мероприятия» (пока заглушка).
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppUi.screenPaddingAll,
        child: Text(
          'Скоро здесь появятся мероприятия',
          textAlign: TextAlign.center,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            height: 24 / 16,
            color: AppColors.caption,
          ),
        ),
      ),
    );
  }
}
