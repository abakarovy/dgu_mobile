import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Заголовок главной страницы: иконка колледжа + текст «КОЛЛЕДЖ ДГУ».
class HomeHeaderTitle extends StatelessWidget {
  const HomeHeaderTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_icon.png',
          height: AppUi.appBarIconSize,
          width: AppUi.appBarIconSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: AppUi.spacingS),
        Text(
          'Колледж ДГУ',
          style: AppTextStyle.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            shadows: const [
              Shadow(
                color: Colors.black,
                offset: Offset(0.35, 0),
                blurRadius: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
