import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Строка контакта на экране поддержки: описание сверху (uppercase), название снизу, иконка слева в контейнере, chevron справа.
class SupportContactRow extends StatelessWidget {
  const SupportContactRow({
    super.key,
    required this.description,
    required this.title,
    required this.iconPath,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.onTap,
    this.showShadow = true,
  });

  final String description;
  final String title;
  final String iconPath;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.radiusM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppUi.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppUi.spacingM,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppUi.supportContactIconPadding),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius:
                        BorderRadius.circular(AppUi.profileRowIconRadius),
                  ),
                  child: SvgPicture.asset(
                    iconPath,
                    width: AppUi.supportContactIconSize,
                    height: AppUi.supportContactIconSize,
                    colorFilter: ColorFilter.mode(
                      iconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: AppUi.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        description.toUpperCase(),
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                          height: 15 / 10,
                          letterSpacing: 0.5,
                          color: AppColors.notificationSubtitle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 20 / 14,
                          color: AppColors.supportContactTitle,
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
