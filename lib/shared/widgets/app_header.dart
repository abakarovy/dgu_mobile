import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_ui.dart';
import '../../core/theme/app_text_styles.dart';

/// Кнопка «назад» для вложенных экранов — тот же вид, что на «Настройки».
Widget appHeaderNestedBackLeading(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.of(context).maybePop(),
    behavior: HitTestBehavior.opaque,
    child: const Center(
      child: Icon(
        Icons.arrow_back_ios_new,
        size: 20,
        color: AppColors.textPrimary,
      ),
    ),
  );
}

/// Стиль заголовка [AppHeader] для вложенных экранов (как «Настройки»).
TextStyle get appHeaderNestedTitleStyle => AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      height: 24 / 18,
      color: AppColors.textPrimary,
    );

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.onPressed,
    required this.headerTitle,
    this.leading,
    this.showNotificationIcon = false,
    this.actions,
  });

  final VoidCallback? onPressed;
  final Widget headerTitle;
  /// Если задан, показывается слева (например, стрелка назад). Иконка уведомлений при этом в правой части по [showNotificationIcon].
  final Widget? leading;
  /// Показывать ли иконку уведомления справа в AppBar.
  final bool showNotificationIcon;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final hasLeading = leading != null;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: hasLeading ? leading : null,
      leadingWidth: hasLeading ? kToolbarHeight : null,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.only(
          left: hasLeading ? 0 : AppUi.appBarPaddingH,
          right: AppUi.appBarPaddingH,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: headerTitle,
        ),
      ),
      centerTitle: false,
      actions: actions ??
          (showNotificationIcon
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: AppUi.appBarPaddingH),
                    child: IconButton(
                      style: IconButton.styleFrom(padding: const EdgeInsets.all(15)),
                      icon: SvgPicture.asset(
                        'assets/icons/notifi.svg',
                        width: AppUi.appBarNotifiSize,
                        height: AppUi.appBarNotifiSize,
                      ),
                      onPressed: onPressed,
                    ),
                  ),
                ]
              : null),
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
