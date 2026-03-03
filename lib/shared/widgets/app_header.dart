import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.onPressed, required this.headerTitle});

  final VoidCallback? onPressed;
  final Widget headerTitle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      title: headerTitle,
      centerTitle: false,
      actions: [ 
        IconButton(
          style: IconButton.styleFrom(padding: EdgeInsets.all(15)),
          icon: SvgPicture.asset(
            'assets/icons/notification_icon.svg',
            width: 24,
            height: 24,
          ),
          onPressed: onPressed,
        )
      ],
    );
    
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
