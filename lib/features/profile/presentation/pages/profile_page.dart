import 'dart:io';

import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_constants.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/navigation/nav_bar_edit_host.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/api/api_exception.dart';
import '../../../../data/models/user_model.dart';
import '../widgets/profile_row_button.dart';

/// Вкладка «Профиль» — данные аккаунта, образование, личные данные и настройки.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _savedAvatarPath;
  UserModel? _me;
  final _parentEmailCtrl = TextEditingController();
  bool _invitingParent = false;

  @override
  void initState() {
    super.initState();
    _me = _readCachedMe();
    _parentEmailCtrl.text = (_me?.parentEmail ?? '').trim();
    _loadAvatarPath();
    _refreshMeInBackground();
  }

  @override
  void dispose() {
    _parentEmailCtrl.dispose();
    super.dispose();
  }

  UserModel? _readCachedMe() {
    final cached = AppContainer.jsonCache.getJsonMap('auth:me');
    if (cached == null) return null;
    try {
      return UserModel.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshMeInBackground() async {
    try {
      final fresh = await AppContainer.authApi
          .getMe()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('auth:me', fresh.toJson());
      if (mounted) {
        setState(() {
          _me = fresh;
          if ((_parentEmailCtrl.text.trim().isEmpty) &&
              ((fresh.parentEmail ?? '').trim().isNotEmpty)) {
            _parentEmailCtrl.text = (fresh.parentEmail ?? '').trim();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _inviteParent() async {
    if (_invitingParent) return;
    final me = _me;
    if (me == null) return;
    if (me.role != 'student') return;
    if ((me.parentEmail ?? '').trim().isNotEmpty) return;

    final email = _parentEmailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() => _invitingParent = true);
    try {
      await AppContainer.accountApi.inviteParent(parentEmail: email);

      // Оптимистично отображаем сразу, а затем подтягиваем /auth/me.
      final updated = UserModel(
        id: me.id,
        email: me.email,
        fullName: me.fullName,
        role: me.role,
        studentBookNumber: me.studentBookNumber,
        parentEmail: email,
        course: me.course,
        direction: me.direction,
        groupId: me.groupId,
        department: me.department,
        bio: me.bio,
        isActive: me.isActive,
        createdAt: me.createdAt,
      );
      await AppContainer.jsonCache.setJson('auth:me', updated.toJson());
      if (mounted) setState(() => _me = updated);

      // Если бэк обновляет parent_email не сразу — это просто обновит кэш.
      await _refreshMeInBackground();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Приглашение отправлено')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? e.message : 'Ошибка';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _invitingParent = false);
    }
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
          _buildAccountInfo(context, _me),
          const SizedBox(height: 28),
          _buildPersonalDataSection(context, _me),
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

  Widget _buildPersonalDataSection(BuildContext context, UserModel? me) {
    final parentEmail = (me?.parentEmail ?? '').trim();
    final canInviteParent = (me?.role == 'student') && parentEmail.isEmpty;

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
          subtitle: (me?.studentBookNumber == null || me!.studentBookNumber!.isEmpty)
              ? '-'
              : me.studentBookNumber!,
          onTap: () => context.push('/app/profile/student-id'),
          titleColor: AppColors.textPrimary,
          iconColor: AppColors.primaryBlue,
          iconBackgroundColor: const Color(0xFFEFF6FF),
        ),
        const SizedBox(height: 10),
        ProfileRowButton(
          iconPath: 'assets/icons/card.svg',
          title: 'Заказать справку',
          subtitle: 'Справка c места учебы',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Скоро будет доступно')),
            );
          },
          titleColor: AppColors.textPrimary,
        ),
        const SizedBox(height: 10),
        ProfileRowButton(
          iconPath: 'assets/icons/mail.svg',
          title: 'E-mail',
          subtitle: 'Подтверждение по коду из письма',
          onTap: () => context.push('/account/email-change'),
          titleColor: AppColors.textPrimary,
        ),
        const SizedBox(height: 10),
        ProfileRowButton(
          iconPath: 'assets/icons/card.svg',
          title: 'Сброс пароля',
          subtitle: 'Сброс по ссылке',
          onTap: () => context.push('/account/password-reset'),
          titleColor: AppColors.textPrimary,
        ),
        if (me?.role == 'student') ...[
          const SizedBox(height: 18),
          Text(
            'РОДИТЕЛЬ',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              height: 16.5 / 11,
              letterSpacing: 1.65,
              color: AppColors.caption,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppUi.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  parentEmail.isEmpty
                      ? 'Укажите почту родителя — отправим приглашение.'
                      : 'Приглашение отправлено на:',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    height: 18 / 13,
                    color: AppColors.notificationSubtitle,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _parentEmailCtrl,
                  enabled: canInviteParent && !_invitingParent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppUi.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'parent@email.ru',
                  ),
                ),
                if (canInviteParent) ...[
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _invitingParent ? null : _inviteParent,
                    child: Text(_invitingParent ? 'Отправляем…' : 'Пригласить'),
                  ),
                ],
              ],
            ),
          ),
        ],
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
          iconPath: 'assets/icons/home_icon.svg',
          title: 'Настроить нижнее меню',
          subtitle: 'Порядок вкладок в панели',
          onTap: NavBarEditHost.requestEditMode,
          titleColor: AppColors.textPrimary,
          iconColor: AppColors.primaryBlue,
          iconBackgroundColor: const Color(0xFFEFF6FF),
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

  Widget _buildAccountInfo(BuildContext context, UserModel? me) {
    final hasAvatar = _savedAvatarPath != null &&
        _savedAvatarPath!.isNotEmpty &&
        File(_savedAvatarPath!).existsSync();

    final fullName = me?.fullName ?? '—';
    final groupLine = _buildGroupLine(me);

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
          fullName,
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
          groupLine,
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

  String _buildGroupLine(UserModel? me) {
    final course = me?.course;
    final direction = me?.direction;
    final groupId = me?.groupId;

    final parts = <String>[];
    if (groupId != null) parts.add('Группа $groupId');
    if (course != null) parts.add('$course курс');
    if (direction != null && direction.trim().isNotEmpty) parts.add(direction.trim());
    return parts.isEmpty ? '—' : parts.join(' • ');
  }

}
