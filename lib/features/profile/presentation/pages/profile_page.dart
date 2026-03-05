import 'dart:io';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_constants.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/profile_row_button.dart';

/// Вкладка «Профиль» — данные аккаунта, образование, личные данные и настройки.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _savedAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadAvatarPath();
  }

  Future<void> _loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(AppConstants.profileAvatarPathKey);
    if (path != null && mounted) {
      setState(() => _savedAvatarPath = path);
    }
  }

  Future<void> _pickAndSaveAvatar() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/${AppConstants.profileAvatarFileName}');
      await file.writeAsBytes(await xFile.readAsBytes());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.profileAvatarPathKey, file.path);
      if (mounted) {
        setState(() => _savedAvatarPath = file.path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить фото')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppUi.spacingXl),
          _buildAccountInfo(context),
          const SizedBox(height: AppUi.spacingXl),
          _buildEducationInfo(context),
          const SizedBox(height: 28),
          _buildPersonalDataSection(context),
          const SizedBox(height: 20),
          _buildSettingsSection(context),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'СТУДЕНТ ДГУ v1.0.0',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  height: 15 / 10,
                  letterSpacing: 2,
                  color: AppColors.lightGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPersonalDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ЛИЧНЫЕ ДАННЫЕ',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            height: 16.5 / 11,
            letterSpacing: 1.65,
            color: AppColors.caption,
          ),
        ),
        const SizedBox(height: AppUi.spacingM),
        ProfileRowButton(
          iconPath: 'assets/icons/profile.svg',
          title: 'Студенческий билет',
          subtitle: '2021-0452',
          onTap: () => context.push('/app/profile/student-id'),
          titleColor: AppColors.textPrimary,
          iconColor: AppColors.primaryBlue,
          iconBackgroundColor: const Color(0xFFEFF6FF),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'НАСТРОЙКИ',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            height: 16.5 / 11,
            letterSpacing: 1.65,
            color: AppColors.caption,
          ),
        ),
        const SizedBox(height: AppUi.spacingM),
        ProfileRowButton(
          iconPath: 'assets/icons/notification_icon.svg',
          title: 'Уведомления',
          subtitle: 'Настроить оповещения',
          onTap: () => context.push('/app/profile/notifications'),
          titleColor: AppColors.textPrimary,
        ),
        const SizedBox(height: 10),
        ProfileRowButton(
          iconPath: 'assets/icons/support_icon.svg',
          title: 'Поддержка',
          subtitle: 'Помощь и контакты',
          onTap: () => context.push('/app/profile/support'),
          titleColor: AppColors.textPrimary,
        ),
        const SizedBox(height: 10),
        ProfileRowButton(
          iconPath: 'assets/icons/logout_icon.svg',
          title: 'Выйти',
          subtitle: 'Завершить сессию',
          onTap: () async {
            await AppContainer.authRepository.logout();
            if (context.mounted) context.go('/login');
          },
          titleColor: Colors.red,
          iconBackgroundColor: const Color(0xFFFEF2F2),
          iconColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAccountInfo(BuildContext context) {
    final hasAvatar = _savedAvatarPath != null &&
        _savedAvatarPath!.isNotEmpty &&
        File(_savedAvatarPath!).existsSync();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
                  width: AppUi.avatarSize,
                  height: AppUi.avatarSize,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                border: Border.all(
                  color: Colors.white,
                  width: AppUi.avatarBorderWidth,
                ),
                borderRadius: BorderRadius.circular(AppUi.avatarRadius),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A000000),
                    offset: const Offset(0, 10),
                    blurRadius: 25,
                    spreadRadius: 0,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: hasAvatar
                  ? Image.file(
                      File(_savedAvatarPath!),
                      fit: BoxFit.cover,
                      width: AppUi.avatarSize,
                      height: AppUi.avatarSize,
                    )
                  : Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.caption,
                    ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: GestureDetector(
                onTap: _pickAndSaveAvatar,
                child: Container(
                  width: AppUi.profileEditButtonSize,
                  height: AppUi.profileEditButtonSize,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightGreen.withValues(alpha: 0.2),
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppUi.spacingM),
        Text(
          'Имя Фамилия',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            height: 36 / 24,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppUi.spacingXs),
        Text(
          'ИСИП-41 • Информационные системы и программирование',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 21 / 14,
            color: AppColors.caption,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEducationInfo(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(
          child: _StatCard(label: 'Курс', value: '4'),
        ),
        const SizedBox(width: AppUi.spacingBetweenCards),
        Expanded(
          child: _StatCard(label: 'Средний балл', value: '4.92'),
        ),
        const SizedBox(width: AppUi.spacingBetweenCards),
          Expanded(
            child: _StatCard(label: 'Пропуски', value: '4ч'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppUi.contentPaddingV, horizontal: AppUi.spacingS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.statCardRadius),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: AppUi.statCardLabelHeight,
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  height: 15 / 10,
                  letterSpacing: 1,
                  color: AppColors.caption,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              height: 27 / 18,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
