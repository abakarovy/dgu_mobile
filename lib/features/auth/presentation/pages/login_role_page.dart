import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';

class LoginRolePage extends StatelessWidget {
  const LoginRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final paddingH =
        width > 0 ? (AppUi.screenPaddingH * width / 448).clamp(16.0, 32.0) : AppUi.screenPaddingH;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(paddingH, 32, paddingH, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: AppUi.loginIconBoxSize,
                  height: AppUi.loginIconBoxSize,
                  decoration: BoxDecoration(
                    color: AppColors.loginPrimary,
                    borderRadius: BorderRadius.circular(AppUi.loginIconBoxRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.loginPrimary.withValues(alpha: 0.2),
                        offset: const Offset(0, 8),
                        blurRadius: 10,
                        spreadRadius: -6,
                      ),
                      BoxShadow(
                        color: AppColors.loginPrimary.withValues(alpha: 0.2),
                        offset: const Offset(0, 20),
                        blurRadius: 25,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/teach.svg',
                      width: AppUi.loginIconSize,
                      height: AppUi.loginIconSize,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppUi.spacingXl),
              Center(
                child: Text(
                  'Вход в систему',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    height: 32 / 24,
                    color: AppColors.loginPrimary,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Выберите тип аккаунта',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppColors.notificationSubtitle,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/login/student'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.loginPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppUi.radiusL),
                  ),
                  textStyle: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                ),
                child: const Text('Я студент'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(
                  '/login/email',
                  extra: const {'role': 'parent', 'mode': 'login'},
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.loginPrimary,
                  side: BorderSide(color: AppColors.loginPrimary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppUi.radiusL),
                  ),
                  textStyle: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                ),
                child: const Text('Я родитель'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

