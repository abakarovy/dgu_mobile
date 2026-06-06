import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';

/// Настройки сотрудника (выход из аккаунта).
class StaffSettingsPage extends StatelessWidget {
  const StaffSettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AppContainer.authRepository.logout();
    if (!context.mounted) return;
    context.go('/public/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Настройки', style: appHeaderNestedTitleStyle),
        showNotificationIcon: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppUi.screenPaddingH),
        children: [
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppUi.radiusL),
            child: InkWell(
              onTap: () => _logout(context),
              borderRadius: BorderRadius.circular(AppUi.radiusL),
              child: Container(
                padding: const EdgeInsets.all(AppUi.spacingL),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppUi.radiusL),
                  border: Border.all(
                    color: AppColors.lightGrey.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(width: AppUi.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Выйти',
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Завершить сеанс на этом устройстве',
                            style: AppTextStyle.inter(
                              fontSize: 13,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
