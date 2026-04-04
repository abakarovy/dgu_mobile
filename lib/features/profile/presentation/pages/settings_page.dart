import 'dart:async';
import 'dart:io';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_constants.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/data/api/api_exception.dart';
import 'package:dgu_mobile/data/models/notification_preferences_model.dart';
import 'package:dgu_mobile/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/widgets/app_header.dart';

/// Настройки: шапка как у вложенных экранов профиля, блок как на профиле, уведомления, выход и поддержка.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  UserModel? _me;
  String? _avatarPath;
  NotificationPreferencesModel? _prefs;
  bool _loadingPrefs = true;
  bool _savingPrefs = false;
  bool _loggingOut = false;

  static const Color _muted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _me = _readCachedMe();
    _hydratePrefsFromCache();
    unawaited(_loadAvatarPath());
    unawaited(_loadPrefs());
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

  void _hydratePrefsFromCache() {
    try {
      final cached = AppContainer.jsonCache.getJsonMap('mobile:notification-preferences');
      if (cached != null) {
        _prefs = NotificationPreferencesModel.fromJson(cached);
      }
    } catch (_) {}
  }

  Future<void> _loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(AppConstants.profileAvatarPathKey);
    if (mounted) setState(() => _avatarPath = path);
  }

  Future<void> _loadPrefs() async {
    setState(() => _loadingPrefs = true);
    try {
      final fresh = await AppContainer.notificationPreferencesApi.getMy();
      await AppContainer.jsonCache.setJson(
        'mobile:notification-preferences',
        fresh.toPatchJson(),
      );
      if (mounted) setState(() => _prefs = fresh);
    } catch (_) {
      // кэш / дефолты
    } finally {
      if (mounted) setState(() => _loadingPrefs = false);
    }
  }

  Future<void> _patch(NotificationPreferencesModel patch) async {
    if (_savingPrefs) return;
    setState(() => _savingPrefs = true);
    try {
      final fresh = await AppContainer.notificationPreferencesApi.patch(patch);
      await AppContainer.jsonCache.setJson(
        'mobile:notification-preferences',
        fresh.toPatchJson(),
      );
      if (mounted) setState(() => _prefs = fresh);
    } catch (e) {
      if (mounted) {
        final msg = (e is ApiException) ? e.message : 'Ошибка';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  Future<void> _onLogout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await AppContainer.authRepository.logout();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось выйти')),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final fullName = (me?.fullName ?? '').trim();
    final p = _prefs ??
        const NotificationPreferencesModel(
          pushNewGrades: true,
          pushScheduleChange: true,
          pushAssignmentDeadlines: true,
          pushCollegeNews: true,
          pushCollegeEvents: true,
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leadingLeftPadding: 6,
        leading: GestureDetector(
          onTap: () => context.pop(),
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        headerTitle: Text(
          'Настройки',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 24 / 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingsProfileHero(
              fullName: fullName.isEmpty ? '—' : fullName,
              avatarPath: _avatarPath,
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) {
                      final w = MediaQuery.sizeOf(context).width;
                      final iw = w * (7 / 402);
                      final ih = w * (7.78 / 402);
                      return SvgPicture.asset(
                        'assets/icons/notification_icon.svg',
                        width: iw,
                        height: ih,
                        colorFilter: const ColorFilter.mode(_muted, BlendMode.srcIn),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Уведомления',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 8.56,
                      height: 1.0,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loadingPrefs)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsToggleCard(
                    title: 'Новые оценки',
                    subtitle: 'Получать уведомления о новых оценках',
                    value: p.pushNewGrades,
                    onChanged: (v) => _patch(p.copyWith(pushNewGrades: v)),
                  ),
                  const SizedBox(height: 10),
                  _SettingsToggleCard(
                    title: 'Изменения в расписании',
                    subtitle: 'Оповещать о переносе пар',
                    value: p.pushScheduleChange,
                    onChanged: (v) => _patch(p.copyWith(pushScheduleChange: v)),
                  ),
                  const SizedBox(height: 10),
                  _SettingsToggleCard(
                    title: 'Дедлайны заданий',
                    subtitle: 'Напоминания о сроках сдачи',
                    value: p.pushAssignmentDeadlines,
                    onChanged: (v) => _patch(p.copyWith(pushAssignmentDeadlines: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Дополнительные',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 8.56,
                  height: 1.0,
                  color: _muted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SettingsToggleCard(
                title: 'Новости колледжа',
                subtitle: 'Важные события и объявления',
                value: p.pushCollegeNews,
                onChanged: (v) => _patch(p.copyWith(pushCollegeNews: v)),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _FooterActionButton(
                      height: 39,
                      border: Border.all(color: const Color(0xFFC84547), width: 0.68),
                      background: const Color(0x26C84547),
                      innerBoxColor: const Color(0xFFFEF2F2),
                      innerRadius: 9,
                      innerSize: 29,
                      iconAsset: 'assets/icons/exit.svg',
                      iconSize: 15,
                      label: 'Выйти из аккаунта',
                      labelColor: const Color(0xFFC84547),
                      onTap: _loggingOut ? null : _onLogout,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _FooterActionButton(
                      height: 39,
                      border: Border.all(color: const Color(0xFF9A9A9A), width: 0.68),
                      background: const Color(0x26747474),
                      innerBoxColor: const Color(0xFFF8FAFC),
                      innerRadius: 9,
                      innerSize: 29,
                      iconAsset: 'assets/icons/help.svg',
                      iconSize: 15,
                      label: 'Поддержка',
                      labelColor: const Color(0xFF515151),
                      onTap: () => context.push('/app/profile/support'),
                    ),
                  ),
                ],
              ),
            ),
            if (_savingPrefs)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Сохраняем…',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Верхний блок как на экране профиля: градиент, аватар, ФИО, «Колледж ДГУ».
class _SettingsProfileHero extends StatelessWidget {
  const _SettingsProfileHero({
    required this.fullName,
    required this.avatarPath,
  });

  final String fullName;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 309,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF224AB9),
                  Color(0xFF0069FF),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/profile_image.png',
              fit: BoxFit.fitHeight,
              alignment: Alignment.centerRight,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: Colors.white, width: 3.34),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        offset: Offset(0, 8.35),
                        blurRadius: 20.86,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: _avatar(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 20.03,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Колледж ДГУ',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.5,
                    height: 1.0,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final p = avatarPath;
    if (p != null && p.isNotEmpty) {
      final f = File(p);
      return Image.file(f, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback());
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: const Icon(Icons.person, color: Colors.white, size: 48),
    );
  }
}

class _SettingsToggleCard extends StatelessWidget {
  const _SettingsToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 12, right: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(2, 4),
            blurRadius: 12.9,
            spreadRadius: 0,
            color: Color(0x26000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.16,
                    height: 1.0,
                    color: const Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 8.56,
                    height: 1.2,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          _PillSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const double _w = 40;
  static const double _h = 20.4;
  static const double _thumb = 15;
  static const double _pad = 2.5;

  @override
  Widget build(BuildContext context) {
    final onColor = const Color(0xFF2664EB);
    final offColor = const Color(0xFFBDBDBD);
    final thumbLeft = value ? _w - _pad - _thumb : _pad;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _w,
        height: _h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _w,
              height: _h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(45),
                color: value ? onColor : offColor,
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: thumbLeft,
              top: (_h - _thumb) / 2,
              child: Container(
                width: _thumb,
                height: _thumb,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterActionButton extends StatelessWidget {
  const _FooterActionButton({
    required this.height,
    required this.border,
    required this.background,
    required this.innerBoxColor,
    required this.innerRadius,
    required this.innerSize,
    required this.iconAsset,
    required this.iconSize,
    required this.label,
    required this.labelColor,
    this.onTap,
  });

  final double height;
  final BoxBorder border;
  final Color background;
  final Color innerBoxColor;
  final double innerRadius;
  final double innerSize;
  final String iconAsset;
  final double iconSize;
  final String label;
  final Color labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        padding: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: border,
          color: background,
        ),
        child: Row(
          children: [
            Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                color: innerBoxColor,
                borderRadius: BorderRadius.circular(innerRadius),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconAsset,
                  width: iconSize,
                  height: iconSize,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.1,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
