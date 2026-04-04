import 'dart:async';
import 'dart:io';
import 'dart:math' show min;

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

    final size = MediaQuery.sizeOf(context);
    const figmaW = 402.0;
    const figmaH = 874.0;
    final layoutScale = min(size.width / figmaW, size.height / figmaH);
    final hPad = 12 * layoutScale;
    final gapSection = 16 * layoutScale;
    final gapBlock = 30 * layoutScale;
    final gapToggle = 10 * layoutScale;
    // Секции «Уведомления» / «Дополнительные»: в 1.5× к прежнему визуалу.
    final sectionLabelFs = 8.56 * layoutScale * 1.5;
    final sectionIconW = size.width * (7 / figmaW) * 1.5;
    final sectionIconH = size.width * (7.78 / figmaW) * 1.5;

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
        padding: EdgeInsets.only(bottom: 32 * layoutScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingsProfileHero(
              layoutScale: layoutScale,
              fullName: fullName.isEmpty ? '—' : fullName,
              avatarPath: _avatarPath,
            ),
            SizedBox(height: gapBlock),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/notification_icon.svg',
                    width: sectionIconW,
                    height: sectionIconH,
                    colorFilter: const ColorFilter.mode(_muted, BlendMode.srcIn),
                  ),
                  SizedBox(width: 6 * layoutScale),
                  Text(
                    'Уведомления',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: sectionLabelFs,
                      height: 1.0,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gapSection),
            if (_loadingPrefs)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: LinearProgressIndicator(minHeight: 2 * layoutScale),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsToggleCard(
                    layoutScale: layoutScale,
                    title: 'Новые оценки',
                    subtitle: 'Получать уведомления о новых оценках',
                    value: p.pushNewGrades,
                    onChanged: (v) => _patch(p.copyWith(pushNewGrades: v)),
                  ),
                  SizedBox(height: gapToggle),
                  _SettingsToggleCard(
                    layoutScale: layoutScale,
                    title: 'Изменения в расписании',
                    subtitle: 'Оповещать о переносе пар',
                    value: p.pushScheduleChange,
                    onChanged: (v) => _patch(p.copyWith(pushScheduleChange: v)),
                  ),
                  SizedBox(height: gapToggle),
                  _SettingsToggleCard(
                    layoutScale: layoutScale,
                    title: 'Дедлайны заданий',
                    subtitle: 'Напоминания о сроках сдачи',
                    value: p.pushAssignmentDeadlines,
                    onChanged: (v) => _patch(p.copyWith(pushAssignmentDeadlines: v)),
                  ),
                ],
              ),
            ),
            SizedBox(height: gapBlock),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Text(
                'Дополнительные',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: sectionLabelFs,
                  height: 1.0,
                  color: _muted,
                ),
              ),
            ),
            SizedBox(height: gapSection),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _SettingsToggleCard(
                layoutScale: layoutScale,
                title: 'Новости колледжа',
                subtitle: 'Важные события и объявления',
                value: p.pushCollegeNews,
                onChanged: (v) => _patch(p.copyWith(pushCollegeNews: v)),
              ),
            ),
            SizedBox(height: gapSection),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  Expanded(
                    child: _FooterActionButton(
                      layoutScale: layoutScale,
                      height: 39 * layoutScale,
                      border: Border.all(
                        color: const Color(0xFFC84547),
                        width: 0.68 * layoutScale,
                      ),
                      background: const Color(0x26C84547),
                      innerBoxColor: const Color(0xFFFEF2F2),
                      innerRadius: 9 * layoutScale,
                      innerSize: 29 * layoutScale,
                      iconAsset: 'assets/icons/exit.svg',
                      iconSize: 15 * layoutScale,
                      label: 'Выйти из аккаунта',
                      labelColor: const Color(0xFFC84547),
                      onTap: _loggingOut ? null : _onLogout,
                    ),
                  ),
                  SizedBox(width: 20 * layoutScale),
                  Expanded(
                    child: _FooterActionButton(
                      layoutScale: layoutScale,
                      height: 39 * layoutScale,
                      border: Border.all(
                        color: const Color(0xFF9A9A9A),
                        width: 0.68 * layoutScale,
                      ),
                      background: const Color(0x26747474),
                      innerBoxColor: const Color(0xFFF8FAFC),
                      innerRadius: 9 * layoutScale,
                      innerSize: 29 * layoutScale,
                      iconAsset: 'assets/icons/help.svg',
                      iconSize: 15 * layoutScale,
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
                padding: EdgeInsets.only(top: 12 * layoutScale),
                child: Text(
                  'Сохраняем…',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 12 * layoutScale,
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
    required this.layoutScale,
    required this.fullName,
    required this.avatarPath,
  });

  final double layoutScale;
  final String fullName;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final heroH = 248 * layoutScale;
    final avatar = 96 * layoutScale;
    final radius = 30 * layoutScale;
    final borderW = 3.34 * layoutScale;
    final nameSize = 20.03 * layoutScale;
    final subtitleSize = 16.5 * layoutScale;
    return SizedBox(
      height: heroH,
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
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                'assets/images/profile_image.png',
                height: heroH,
                fit: BoxFit.fitHeight,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: avatar,
                  height: avatar,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: Colors.white, width: borderW),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x1A000000),
                        offset: Offset(0, 8.35 * layoutScale),
                        blurRadius: 20.86 * layoutScale,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: _avatar(layoutScale),
                  ),
                ),
                SizedBox(height: 8 * layoutScale),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: nameSize,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3 * layoutScale),
                Text(
                  'Колледж ДГУ',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: subtitleSize,
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

  Widget _avatar(double layoutScale) {
    final p = avatarPath;
    if (p != null && p.isNotEmpty) {
      final f = File(p);
      return Image.file(f, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback(layoutScale));
    }
    return _fallback(layoutScale);
  }

  Widget _fallback(double layoutScale) {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: Icon(Icons.person, color: Colors.white, size: 48 * layoutScale),
    );
  }
}

class _SettingsToggleCard extends StatelessWidget {
  const _SettingsToggleCard({
    required this.layoutScale,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final double layoutScale;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final r = 26.4 * layoutScale;
    final padL = 14.4 * layoutScale;
    final padR = 12 * layoutScale;
    final padV = 12 * layoutScale;
    return Container(
      constraints: BoxConstraints(minHeight: 64 * layoutScale),
      padding: EdgeInsets.only(left: padL, right: padR, top: padV, bottom: padV),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            offset: Offset(4 * layoutScale, 5 * layoutScale),
            blurRadius: 4 * layoutScale,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.16 * layoutScale,
                    height: 1.0,
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 4 * layoutScale),
                Text(
                  subtitle,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 8.56 * layoutScale,
                    height: 1.25,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          _PillSwitch(layoutScale: layoutScale, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({
    required this.layoutScale,
    required this.value,
    required this.onChanged,
  });

  final double layoutScale;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final w = 40 * layoutScale;
    final h = 20.4 * layoutScale;
    final thumb = 15 * layoutScale;
    final pad = 2.5 * layoutScale;
    final onColor = const Color(0xFF2664EB);
    final offColor = const Color(0xFFBDBDBD);
    final thumbLeft = value ? w - pad - thumb : pad;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(45 * layoutScale),
                color: value ? onColor : offColor,
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: thumbLeft,
              top: (h - thumb) / 2,
              child: Container(
                width: thumb,
                height: thumb,
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
    required this.layoutScale,
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

  final double layoutScale;
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
        padding: EdgeInsets.only(left: 6 * layoutScale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10 * layoutScale),
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
            SizedBox(width: 14 * layoutScale),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 11 * layoutScale,
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
