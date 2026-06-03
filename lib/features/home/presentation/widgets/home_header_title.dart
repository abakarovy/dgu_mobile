import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Заголовок главной: роль пользователя или подпись гостя («Абитуриент»).
class HomeHeaderTitle extends StatelessWidget {
  const HomeHeaderTitle({super.key, this.guestMode = false});

  /// Гостевой режим — всегда «Абитуриент».
  final bool guestMode;

  static String labelForRole(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'parent':
        return 'Родитель';
      case 'student':
        return 'Студент';
      default:
        return 'Студент';
    }
  }

  String _resolveLabel() {
    if (guestMode) return 'Абитуриент';
    final cached = AppContainer.jsonCache.getJsonMap('auth:me');
    final role = cached?['role']?.toString();
    return labelForRole(role);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/logo.svg',
          height: AppUi.appBarIconSize,
          width: AppUi.appBarIconSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Text(
          _resolveLabel(),
          style: AppTextStyle.inter(
            fontSize: 14.32,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
