import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Полноэкранная заглушка, когда в Remote Config выключен доступ к бэку.
class AppUnavailableScreen extends StatelessWidget {
  const AppUnavailableScreen({
    super.key,
    required this.onRefresh,
    this.busy = false,
  });

  final Future<void> Function() onRefresh;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 72,
                color: AppColors.primaryBlue.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 28),
              Text(
                'Приложение временно недоступно',
                textAlign: TextAlign.center,
                style: AppTextStyle.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Сервис отключён администратором. Нажмите «Обновить», чтобы проверить доступ снова.',
                textAlign: TextAlign.center,
                style: AppTextStyle.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: AppColors.notificationSubtitle,
                ),
              ),
              const SizedBox(height: 36),
              FilledButton(
                onPressed: busy ? null : () => onRefresh(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lightBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Обновить',
                        style: AppTextStyle.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
