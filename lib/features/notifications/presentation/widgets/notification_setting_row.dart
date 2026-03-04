import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/notification_switch.dart';

/// Строка настройки уведомления: заголовок, описание, переключатель 48×24 (без иконки слева).
class NotificationSettingRow extends StatelessWidget {
  const NotificationSettingRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppUi.spacingM,
            vertical: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 20 / 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        height: 15 / 10,
                        color: AppColors.notificationSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              NotificationSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
