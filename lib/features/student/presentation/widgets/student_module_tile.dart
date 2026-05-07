import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Строка меню «Сервисы студента»: без тени и без splash при нажатии (как чистые карточки в приложении).
class StudentModuleTile extends StatelessWidget {
  const StudentModuleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                  color: accentColor,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: accentColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 1.25,
                                color: AppColors.notificationSubtitle,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppColors.chevronRight, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
