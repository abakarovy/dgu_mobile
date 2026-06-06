import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/staff_capabilities_model.dart';

class StaffModuleTile extends StatelessWidget {
  const StaffModuleTile({
    super.key,
    required this.module,
    required this.icon,
    required this.onTap,
  });

  final StaffModuleModel module;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppUi.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        child: Container(
          padding: const EdgeInsets.all(AppUi.spacingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppUi.radiusL),
            border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.lightBlue),
              ),
              const SizedBox(width: AppUi.spacingM),
              Expanded(
                child: Text(
                  module.label,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.grey.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
