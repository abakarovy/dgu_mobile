import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Строка FAQ: только название, без иконки и описания, chevron справа.
class SupportFaqRow extends StatelessWidget {
  const SupportFaqRow({
    super.key,
    required this.title,
    this.onTap,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.radiusM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppUi.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppUi.spacingM,
              vertical: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_right.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.chevronRight,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
