import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_ui.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.onPressed,
    required this.headerTitle,
    this.leading,
    this.showNotificationIcon = true,
  });

  final VoidCallback? onPressed;
  final Widget headerTitle;
  /// Если задан, показывается слева (например, стрелка назад). Иконка уведомлений при этом в правой части по [showNotificationIcon].
  final Widget? leading;
  /// Показывать ли иконку уведомления справа в AppBar.
  final bool showNotificationIcon;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: leading,
      leadingWidth: leading != null ? 56 : null,
      titleSpacing: leading != null ? 0 : null,
      title: Padding(
        padding: EdgeInsets.only(
          left: leading != null ? 0 : AppUi.screenPaddingH,
        ),
        child: headerTitle,
      ),
      centerTitle: false,
      actions: showNotificationIcon
          ? [
              Padding(
                padding: const EdgeInsets.only(right: AppUi.screenPaddingH),
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
          : null,
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
