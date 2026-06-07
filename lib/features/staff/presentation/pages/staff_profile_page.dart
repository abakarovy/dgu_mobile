import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/media/staff_avatar_picker.dart';
import '../../../../core/staff/staff_module_navigation.dart';
import '../../../../core/staff/teacher_tool_whitelist.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/person_name_format.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/api/staff_api.dart';
import '../../../../data/models/staff_capabilities_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../features/staff/domain/staff_user_roles.dart';
import '../../../../shared/widgets/app_developer_card.dart';
import '../widgets/staff_admin_ui.dart';

enum StaffProfileMode { admin, teacher }

class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({
    super.key,
    this.mode = StaffProfileMode.admin,
  });

  final StaffProfileMode mode;

  @override
  State<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends State<StaffProfilePage> {
  UserModel? _me;
  StaffCapabilitiesModel? _caps;
  bool _loading = true;
  bool _uploadingAvatar = false;
  String? _error;

  static const _toolsWhitelist = kAdminToolModuleIds;

  static const _defaultAdminModules = [
    StaffModuleModel(id: 'news', label: 'Новости', mobileReady: 'full'),
    StaffModuleModel(id: 'groups', label: 'Группы', mobileReady: 'full'),
    StaffModuleModel(id: 'moderation', label: 'Модерация', mobileReady: 'full'),
    StaffModuleModel(id: 'weekly_grades', label: 'Рассылка оценок', mobileReady: 'full'),
    StaffModuleModel(
      id: 'scholarship_rating',
      label: 'Стипендиальный рейтинг',
      mobileReady: 'full',
    ),
    StaffModuleModel(id: 'mobile_app', label: 'Мобильное приложение', mobileReady: 'full'),
  ];

  @override
  void initState() {
    super.initState();
    _me = _readCachedMe();
    _caps = _readCachedCaps();
    if (_me != null) _loading = false;
    unawaited(_refreshProfile());
  }

  UserModel? _readCachedMe() {
    final raw = AppContainer.jsonCache.getJsonMap('auth:me');
    if (raw != null) {
      try {
        return UserModel.fromJson(raw);
      } catch (_) {}
    }
    return null;
  }

  StaffCapabilitiesModel? _readCachedCaps() {
    final raw = AppContainer.jsonCache.getJsonMap(StaffModuleNavigation.cacheKey);
    if (raw == null) return null;
    try {
      return StaffCapabilitiesModel.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final results = await Future.wait([
        AppContainer.staffApi.getProfile(),
        AppContainer.staffApi.getCapabilities(),
      ]);
      final user = results[0] as UserModel;
      final caps = results[1] as StaffCapabilitiesModel;
      await AppContainer.tokenStorage.setUserDataJson(jsonEncode(user.toJson()));
      await AppContainer.jsonCache.setJson('auth:me', user.toJson());
      await AppContainer.jsonCache.setJson(StaffModuleNavigation.cacheKey, caps.toJson());
      if (!mounted) return;
      setState(() {
        _me = user;
        _caps = caps;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_me == null) _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_me == null) _error = 'Не удалось загрузить профиль';
      });
    }
  }

  Future<void> _onAvatarTap() async {
    if (_uploadingAvatar) return;
    final file = await StaffAvatarPicker.pickAndCrop(context);
    if (file == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
    try {
      final avatarUrl = await AppContainer.staffApi.uploadAvatar(file.path);
      final updated = (_me ?? _readCachedMe())?.copyWith(avatarUrl: avatarUrl);
      if (updated != null) {
        await AppContainer.tokenStorage.setUserDataJson(jsonEncode(updated.toJson()));
        await AppContainer.jsonCache.setJson('auth:me', updated.toJson());
      }
      if (!mounted) return;
      setState(() {
        _me = updated ?? _me;
        _uploadingAvatar = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить фото')),
      );
    }
  }

  List<StaffModuleModel> _profileModules(UserModel? me) {
    final caps = _caps;
    var modules = <StaffModuleModel>[];

    if (caps != null) {
      modules = caps.homeModules
          .where((m) => _toolsWhitelist.contains(m.id))
          .toList();
    }

    final isAdmin = caps?.canAccessSiteAdmin == true ||
        caps?.isAdmin == true ||
        me?.canAccessSiteAdmin == true ||
        me?.isAdmin == true;

    if (isAdmin) {
      final ids = modules.map((m) => m.id).toSet();
      for (final d in _defaultAdminModules) {
        if (!ids.contains(d.id)) modules.add(d);
      }
    }

    modules = modules.where((m) => _toolsWhitelist.contains(m.id)).toList();
    modules.sort((a, b) {
      const order = [
        'news',
        'groups',
        'moderation',
        'weekly_grades',
        'scholarship_rating',
        'mobile_app',
      ];
      final ia = order.indexOf(a.id);
      final ib = order.indexOf(b.id);
      return (ia >= 0 ? ia : 99).compareTo(ib >= 0 ? ib : 99);
    });
    return modules;
  }

  void _openModule(StaffModuleModel module) {
    final route = StaffModuleNavigation.nativeRouteFor(module);
    if (route != null) {
      if (route == '/staff/users' ||
          route == '/staff/home' ||
          route == '/staff/profile') {
        context.go(route);
      } else {
        context.push(route);
      }
      return;
    }
    if (StaffModuleNavigation.webAdminUrl(module.id) != null) {
      context.push('/staff/web/${module.id}');
    }
  }

  void _openTeacherSection(String route) {
    if (route == '/teacher/journal' ||
        route == '/teacher/content' ||
        route == '/teacher/home') {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  Future<void> _logout() async {
    await AppContainer.authRepository.logout();
    if (!mounted) return;
    context.go('/public/profile');
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final caps = _caps;
    final isTeacherMode = widget.mode == StaffProfileMode.teacher;
    final modules = isTeacherMode ? <StaffModuleModel>[] : _profileModules(me);
    final size = MediaQuery.sizeOf(context);
    const figmaW = 402.0;
    const figmaH = 874.0;
    final layoutScale = min(size.width / figmaW, size.height / figmaH);
    final fullName = formatPersonNameDisplay(me?.fullName ?? '');
    final heroSubtitle = me != null ? _profileHeroSubtitle(me) : 'Сотрудник';

    if (_loading && me == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && me == null) {
      return Center(
        child: Padding(
          padding: AppUi.screenPaddingAll,
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StaffProfileHero(
                layoutScale: layoutScale,
                fullName: fullName.isEmpty ? '—' : fullName,
                position: heroSubtitle,
                avatarUrl: me?.avatarUrl,
                uploading: _uploadingAvatar,
                onAvatarTap: _onAvatarTap,
              ),
              const SizedBox(height: 20),
              if (me != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isTeacherMode) ...[
                        _StaffProfileTeacherSectionsCard(
                          onOpen: _openTeacherSection,
                        ),
                      ] else if (modules.isNotEmpty &&
                          (me.canAccessSiteAdmin ||
                              me.isAdmin ||
                              caps?.canAccessSiteAdmin == true)) ...[
                        _StaffProfileModulesCard(
                          modules: modules,
                          onOpen: _openModule,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _StaffProfileLogoutButton(onLogout: _logout),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
                child: AppDeveloperCard(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _profileHeroSubtitle(UserModel user) {
    final role = user.role.trim().toLowerCase();
    for (final entry in StaffUserRoles.allRoles) {
      if (entry.$1 == role) return entry.$2;
    }
    final pos = (user.position ?? '').trim();
    if (pos.isNotEmpty) return pos;
    return 'Сотрудник';
  }
}

class _StaffProfileHero extends StatelessWidget {
  const _StaffProfileHero({
    required this.layoutScale,
    required this.fullName,
    required this.position,
    required this.avatarUrl,
    required this.uploading,
    required this.onAvatarTap,
  });

  final double layoutScale;
  final String fullName;
  final String position;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final heroH = 248 * layoutScale;
    final avatarW = 96 * layoutScale;
    final avatarH = 128 * layoutScale;
    final radius = 12 * layoutScale;
    final borderW = 3.34 * layoutScale;
    final nameSize = 20.03 * layoutScale;
    final subtitleSize = 16.5 * layoutScale;
    final url = StaffApi.resolveAvatarUrl(avatarUrl);

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
                colors: [Color(0xFF224AB9), Color(0xFF0069FF)],
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * layoutScale),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: uploading ? null : onAvatarTap,
                    child: Container(
                      width: avatarW,
                      height: avatarH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (url.isNotEmpty)
                              Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _fallbackAvatar(layoutScale),
                              )
                            else
                              _fallbackAvatar(layoutScale),
                            if (uploading)
                              Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(radius),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: borderW,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * layoutScale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fullName,
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: nameSize,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 3 * layoutScale),
                        Text(
                          position.isNotEmpty ? position : 'Сотрудник',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar(double layoutScale) {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: Icon(Icons.person, color: Colors.white, size: 48 * layoutScale),
    );
  }
}

class _StaffProfileLogoutButton extends StatelessWidget {
  const _StaffProfileLogoutButton({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppUi.radiusL),
      child: InkWell(
        onTap: () => unawaited(onLogout()),
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        child: Container(
          padding: const EdgeInsets.all(AppUi.spacingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppUi.radiusL),
            border: Border.all(
              color: AppColors.lightGrey.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(width: AppUi.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Выйти',
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Завершить сеанс на этом устройстве',
                      style: AppTextStyle.inter(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffProfileTeacherSectionsCard extends StatelessWidget {
  const _StaffProfileTeacherSectionsCard({required this.onOpen});

  final ValueChanged<String> onOpen;

  static const _sections = [
    (title: 'Журнал', subtitle: 'Предметы и оценки', route: '/teacher/journal', icon: Icons.grade_outlined),
    (title: 'Материалы', subtitle: 'Файлы для групп', route: '/teacher/materials', icon: Icons.folder_outlined),
    (title: 'Контент', subtitle: 'Новости и мероприятия', route: '/teacher/content', icon: Icons.newspaper_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StaffAdminUi.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Мои разделы',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _TeacherSectionRow(
              title: _sections[i].title,
              subtitle: _sections[i].subtitle,
              icon: _sections[i].icon,
              onTap: () => onOpen(_sections[i].route),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeacherSectionRow extends StatelessWidget {
  const _TeacherSectionRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.lightBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyle.inter(
                        fontSize: 12,
                        color: AppColors.caption,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffProfileModulesCard extends StatelessWidget {
  const _StaffProfileModulesCard({
    required this.modules,
    required this.onOpen,
  });

  final List<StaffModuleModel> modules;
  final ValueChanged<StaffModuleModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StaffAdminUi.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Мои инструменты',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Быстрый переход к разделам админки',
            style: AppTextStyle.inter(
              fontSize: 12,
              color: AppColors.caption,
            ),
          ),
          const SizedBox(height: 12),
          ...modules.map((module) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onOpen(module),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            StaffModuleNavigation.iconFor(module.id),
                            size: 20,
                            color: AppColors.lightBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            module.label,
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.grey.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
