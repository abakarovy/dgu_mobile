import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

import '../widgets/profile_row_button.dart';

/// Вкладка «Профиль» — данные аккаунта, образование, личные данные и настройки.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const double _avatarSize = 96;
  static const double _badgeSize = 24;
  static const double _statCardRadius = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAccountInfo(context, theme),
          const SizedBox(height: 24),
          _buildEducationInfo(context, theme),
          const SizedBox(height: 28),
          _buildPersonalDataSection(context, theme),
          const SizedBox(height: 20),
          _buildSettingsSection(context, theme),
          const SizedBox(height: 30,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ДГУ v1.0',
                style: Theme.of(context).appBarTheme.titleTextStyle!.copyWith(color: AppColors.lightGrey, fontSize: 14, letterSpacing: 4)
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPersonalDataSection(BuildContext context, TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ЛИЧНЫЕ ДАННЫЕ',
          style: Theme.of(context).appBarTheme.titleTextStyle!.copyWith(color: AppColors.caption, fontSize: 14)
        ),
        const SizedBox(height: 12),
        ProfileRowButton(
          iconPath: 'assets/icons/profile_icon.svg',
          title: 'Студенческий билет',
          subtitle: '2021-0452',
          onTap: () {},
          titleColor: AppColors.primaryBlue,
          iconColor: AppColors.primaryBlue,
          iconBackgroundColor: AppColors.backgroundBlue,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'НАСТРОЙКИ',
          style: Theme.of(context).appBarTheme.titleTextStyle!.copyWith(color: AppColors.caption, fontSize: 14)
        ),
        const SizedBox(height: 12),
        ProfileRowButton(
          iconPath: 'assets/icons/notification_icon.svg',
          title: 'Уведомления',
          subtitle: 'Настроить оповещения',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        ProfileRowButton(
          iconPath: 'assets/icons/support_icon.svg',
          title: 'Поддержка',
          subtitle: 'Помощь и контакты',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        ProfileRowButton(
          iconPath: 'assets/icons/logout_icon.svg',
          title: 'Выйти',
          subtitle: 'Завершить сессию',
          onTap: () {},
          titleColor: Colors.red,
          iconBackgroundColor: Colors.red.withValues(alpha: 0.12),
          iconColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAccountInfo(BuildContext context, TextTheme theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Аватар с бейджем
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: _avatarSize,
              height: _avatarSize,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                border: BoxBorder.all(color: Colors.white, width: 6),
                borderRadius: BorderRadius.circular(_statCardRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ]
              ),
              child: Icon(
                Icons.person,
                size: 48,
                color: AppColors.caption,
              ),
            ),
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: _badgeSize,
                height: _badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  border: BoxBorder.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: AppColors.lightGreen.withAlpha(50), spreadRadius: 1, offset: Offset(0, 2), blurRadius: 4)
                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Имя Фамилия',
          style: theme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'ИСИП-41 • Информационные системы и программирование',
          style: theme.bodyMedium?.copyWith(color: AppColors.caption),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEducationInfo(BuildContext context, TextTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Курс',
            value: '4',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Средний балл',
            value: '4.92',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Пропуски',
            value: '4ч',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ProfilePage._statCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.bodySmall?.copyWith(color: AppColors.caption),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.titleMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
