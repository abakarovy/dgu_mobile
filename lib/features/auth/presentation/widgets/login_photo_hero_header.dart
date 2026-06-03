import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';

/// Назад с экрана входа: pop или профиль гостя, если стек пуст.
void loginNavigateBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/public/profile');
  }
}

/// Шапка на фото: стрелка (left 5) → отступ 10 → заголовок (left 10).
class LoginPhotoHeroHeader extends StatelessWidget {
  const LoginPhotoHeroHeader({
    super.key,
    required this.sf,
    required this.title,
    this.subtitle = 'КОЛЛЕДЖ ДГУ',
  });

  final double sf;
  final String title;
  final String subtitle;

  static const double _arrowLeft = 5;
  static const double _titleLeft = 15;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: _arrowLeft),
          child: GestureDetector(
            onTap: () => loginNavigateBack(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 26,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: _titleLeft),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 111.73 * sf,
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10 * sf),
              Text(
                subtitle,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 32.96 * sf * 1.25,
                  height: 1.0,
                  letterSpacing: -0.82 * sf * 1.25,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
