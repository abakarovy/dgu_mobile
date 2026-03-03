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
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: headerTitle,
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: IconButton(
            style: IconButton.styleFrom(padding: const EdgeInsets.all(15)),
            icon: SvgPicture.asset(
              'assets/icons/notifi.svg',
              width: 20,
              height: 20,
            ),
            onPressed: onPressed,
          ),
        )
      ],
    );
    
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
