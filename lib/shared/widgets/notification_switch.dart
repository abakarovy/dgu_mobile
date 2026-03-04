import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_ui.dart';

/// Переключатель 48×24: трек с отступами 4, круг 16×16.
/// Вкл: трек #003B73, выкл: серый.
class NotificationSwitch extends StatelessWidget {
  const NotificationSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final trackHeight = AppUi.notificationSwitchHeight;
    final thumbSize = AppUi.notificationSwitchThumbSize;
    final trackRadius = AppUi.notificationSwitchRadius;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: AppUi.notificationSwitchWidth,
        height: trackHeight,
        child: Container(
          decoration: BoxDecoration(
            color: value
                ? AppColors.notificationSwitchActive
                : AppColors.notificationSwitchInactive,
            borderRadius: BorderRadius.circular(trackRadius),
          ),
          padding: const EdgeInsets.all(AppUi.notificationSwitchPadding),
          child: Align(
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
