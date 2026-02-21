import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Строка-кнопка: иконка слева (в цветном фоне), колонка заголовок/подзаголовок, chevron справа.
/// Цвета заголовка и иконки задаются параметрами для разных типов строк (например «Выйти» — красным).
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
  /// Цвет заголовка; по умолчанию чёрный.
  final Color? titleColor;
  /// Фон контейнера иконки слева; по умолчанию primary blue.
  final Color? iconBackgroundColor;
  /// Цвет иконки слева; по умолчанию белый (на primary blue).
  final Color? iconColor;

  static const double _iconSize = 24;
  static const double _iconPadding = 12;
  static const double _iconRadius = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final bgColor = iconBackgroundColor ?? AppColors.surfaceLight;
    final leftIconColor = iconColor ?? AppColors.grey;
    final textColor = titleColor ?? Colors.black;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ]
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),   
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(_iconPadding),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(_iconRadius),
                  ),
                  child: SvgPicture.asset(
                    iconPath,
                    width: _iconSize,
                    height: _iconSize,
                    colorFilter: ColorFilter.mode(leftIconColor, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.titleSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.bodySmall?.copyWith(color: AppColors.caption),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_right.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    AppColors.caption,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}
