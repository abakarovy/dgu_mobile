import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Профиль гостя (абитуриент): вход студента или родителя.
class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({super.key});

  static const _afterLoginItems = <(IconData, String)>[
    (Icons.grade_outlined, 'Оценки и журнал'),
    (Icons.calendar_month_outlined, 'Расписание и задания'),
    (Icons.badge_outlined, 'Справки и студенческий билет'),
    (Icons.notifications_outlined, 'Уведомления колледжа'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
          stops: [0.0, 0.22, 0.5],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppUi.screenPaddingH,
          AppUi.spacingL,
          AppUi.screenPaddingH,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RoleLoginCard(
              title: 'Я студент',
              icon: Icons.school_outlined,
              primary: false,
              onTap: () => context.push('/login/student'),
            ),
            const SizedBox(height: AppUi.spacingM),
            _RoleLoginCard(
              title: 'Я родитель',
              icon: Icons.family_restroom_outlined,
              primary: true,
              onTap: () => context.push(
                '/login/email',
                extra: const {'role': 'parent', 'mode': 'login'},
              ),
            ),
            const SizedBox(height: AppUi.spacingXl),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppUi.spacingM),
                Text(
                  'После входа',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUi.spacingM),
            Container(
              padding: const EdgeInsets.all(AppUi.spacingL),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppUi.radiusL),
                border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _afterLoginItems.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppUi.spacingM),
                    _BenefitRow(
                      icon: _afterLoginItems[i].$1,
                      label: _afterLoginItems[i].$2,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleLoginCard extends StatelessWidget {
  const _RoleLoginCard({
    required this.title,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        child: Ink(
          padding: const EdgeInsets.all(AppUi.spacingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppUi.radiusL),
            gradient: primary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                  )
                : null,
            color: primary ? null : Colors.white,
            border: primary
                ? null
                : Border.all(color: AppColors.lightBlue.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: (primary ? AppColors.lightBlue : Colors.black).withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.backgroundBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: primary ? Colors.white : AppColors.lightBlue,
                ),
              ),
              const SizedBox(width: AppUi.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: primary ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: primary ? Colors.white.withValues(alpha: 0.9) : AppColors.lightBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.backgroundBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.lightBlue),
        ),
        const SizedBox(width: AppUi.spacingM),
        Expanded(
          child: Text(
            label,
            style: AppTextStyle.inter(
              fontSize: 14,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
