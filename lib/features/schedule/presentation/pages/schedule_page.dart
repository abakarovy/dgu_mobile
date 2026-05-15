import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/network_degraded_banner.dart';

// Полноценный экран недели (календарь, запросы GET /1c/schedule) временно отключён —
// см. историю git. Включение: восстановить прежнюю реализацию [SchedulePage].

/// Заглушка: расписание в разработке (без запросов к API расписания).
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppHeader(
              leading: appHeaderNestedBackLeading(context),
              headerTitle:
                  Text('Расписание', style: appHeaderNestedTitleStyle),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      size: 56,
                      color: AppColors.primaryBlue.withValues(alpha: 0.55),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Раздел в разработке',
                      textAlign: TextAlign.center,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Скоро здесь будет расписание занятий. '
                      'Следите за обновлениями приложения.',
                      textAlign: TextAlign.center,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        height: 1.4,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
