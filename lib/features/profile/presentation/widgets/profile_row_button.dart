import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Строка-кнопка: иконка слева (в цветном фоне), заголовок/подзаголовок, chevron справа.
class ProfileRowButton extends StatelessWidget {
  const ProfileRowButton({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.titleColor,
    this.iconBackgroundColor,
    this.iconColor,
  });

  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final bgColor = iconBackgroundColor ?? AppColors.surfaceLight;
    final leftIconColor = iconColor ?? AppColors.grey;
    final textColor = titleColor ?? AppColors.textPrimary;

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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppUi.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppUi.spacingM, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppUi.profileRowIconPadding),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppUi.profileRowIconRadius),
                  ),
                  child: SvgPicture.asset(
                    iconPath,
                    width: AppUi.profileRowIconSize,
                    height: AppUi.profileRowIconSize,
                    colorFilter: ColorFilter.mode(leftIconColor, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: AppUi.spacingM),
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
                          height: 21 / 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 18 / 12,
                          color: AppColors.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_right.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.chevronRight,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
