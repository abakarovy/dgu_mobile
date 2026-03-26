import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Баннер на главной: контейнер с приветствием и данными студента, картинка card.svg справа снизу.
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({
    super.key,
    required this.fullName,
    this.groupLabel,
    this.performanceLabel,
  });

  final String fullName;
  final String? groupLabel;
  final String? performanceLabel;

  @override
  Widget build(BuildContext context) {
    final groupValue = (groupLabel ?? '').trim().isEmpty ? '-' : groupLabel!.trim();
    final perfValue =
        (performanceLabel ?? '').trim().isEmpty ? '-' : performanceLabel!.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(AppUi.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0x4D003882),
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: -3,
          ),
        ],
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: AppUi.screenPaddingAll,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Привет, студент!',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.0,
                    color: AppColors.textOnBanner,
                  ),
                ),
                const SizedBox(height: AppUi.spacingXs),
                Text(
                  fullName,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    height: 1.0,
                    color: AppColors.textOnBanner,
                  ),
                ),
                const SizedBox(height: AppUi.spacingL),
                Wrap(
                  spacing: AppUi.spacingM,
                  runSpacing: AppUi.spacingS,
                  children: [
                    _InfoChip(label: 'Группа', value: groupValue),
                    _InfoChip(label: 'Успеваемость', value: perfValue),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: -5,
            child: SvgPicture.asset(
              'assets/icons/card.svg',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppUi.radiusM),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppUi.spacingM, vertical: AppUi.spacingS),
          decoration: BoxDecoration(
            color: AppColors.chipBackgroundOnBanner,
            borderRadius: BorderRadius.circular(AppUi.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                  height: 1.0,
                  color: AppColors.textOnBanner,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.0,
                  color: AppColors.textOnBanner,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
