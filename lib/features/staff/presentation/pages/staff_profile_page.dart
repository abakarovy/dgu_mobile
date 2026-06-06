import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/media/staff_avatar_picker.dart';
import '../../../../core/staff/staff_module_navigation.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/person_name_format.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/api/staff_api.dart';
import '../../../../data/models/staff_capabilities_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../features/staff/domain/staff_user_roles.dart';
import '../../../../shared/widgets/app_developer_card.dart';
import '../widgets/staff_admin_ui.dart';

String? _formatJoinedDate(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  try {
    return DateFormat('dd.MM.yyyy').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return null;
  }
}

/// Вкладка «Профиль» сотрудника — в стиле студенческого профиля.
class StaffProfilePage extends StatefulWidget {
  const StaffProfilePage({super.key});

  @override
  State<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends State<StaffProfilePage> {
  UserModel? _me;
  StaffCapabilitiesModel? _caps;
  bool _loading = true;
  bool _uploadingAvatar = false;
  String? _error;

  static const _toolsWhitelist = {
    'news',
    'groups',
    'moderation',
    'weekly_grades',
    'scholarship_rating',
    'mobile_app',
  };

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

  void _copyEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-mail скопирован')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final caps = _caps;
    final modules = _profileModules(me);
    final size = MediaQuery.sizeOf(context);
    const figmaW = 402.0;
    const figmaH = 874.0;
    final layoutScale = min(size.width / figmaW, size.height / figmaH);
    final fullName = formatPersonNameDisplay(me?.fullName ?? '');

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
                position: (me?.position ?? '').trim(),
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
                      _StaffProfileAccountCard(
                        user: me,
                        onCopyEmail: () => _copyEmail(me.email),
                      ),
                      const SizedBox(height: 12),
                      _StaffProfileAccessCard(user: me, caps: caps),
                      if (modules.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _StaffProfileModulesCard(
                          modules: modules,
                          onOpen: _openModule,
                        ),
                      ],
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

class _StaffProfileAccountCard extends StatelessWidget {
  const _StaffProfileAccountCard({
    required this.user,
    required this.onCopyEmail,
  });

  final UserModel user;
  final VoidCallback onCopyEmail;

  @override
  Widget build(BuildContext context) {
    final department = (user.department ?? '').trim();
    final joined = _formatJoinedDate(user.createdAt);
    final bio = (user.bio ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StaffAdminUi.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Аккаунт',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _StaffProfileInfoRow(
            label: 'E-mail',
            value: user.email,
            trailing: IconButton(
              onPressed: onCopyEmail,
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: AppColors.grey,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Скопировать',
            ),
          ),
          if (department.isNotEmpty) ...[
            const SizedBox(height: 10),
            _StaffProfileInfoRow(label: 'Отделение', value: department),
          ],
          if (joined != null) ...[
            const SizedBox(height: 10),
            _StaffProfileInfoRow(label: 'В системе с', value: joined),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            _StaffProfileInfoRow(label: 'О себе', value: bio),
          ],
        ],
      ),
    );
  }
}

class _StaffProfileAccessCard extends StatelessWidget {
  const _StaffProfileAccessCard({
    required this.user,
    required this.caps,
  });

  final UserModel user;
  final StaffCapabilitiesModel? caps;

  @override
  Widget build(BuildContext context) {
    final roleLabel = StaffUserRoles.labelFor(user.role);
    final cabinetTitle = caps?.cabinetTitle ??
        (user.canAccessDepartmentCabinet
            ? 'Кабинет отделения'
            : user.isTeacher
                ? 'Кабинет преподавателя'
                : user.isAdmin
                    ? 'Администрирование'
                    : 'Сотрудник');

    final permissions = <String>[
      if (user.isAdmin || caps?.isAdmin == true) 'Администратор',
      if (user.canAccessSiteAdmin || caps?.canAccessSiteAdmin == true) 'Админка сайта',
      if (user.canAccessAdmissionAdmin || caps?.canAccessAdmissionAdmin == true)
        'Приёмная кампания',
      if (user.canAccessDepartmentCabinet || caps?.canAccessDepartmentCabinet == true)
        'Кабинет отделения',
      if (user.isTeacher || caps?.isTeacher == true) 'Преподаватель',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StaffAdminUi.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Доступ',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  roleLabel,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.lightBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cabinetTitle,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (permissions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in permissions)
                  _StaffProfileAccessChip(label: p),
              ],
            ),
          ],
        ],
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

class _StaffProfileInfoRow extends StatelessWidget {
  const _StaffProfileInfoRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: AppTextStyle.inter(
              fontSize: 13,
              color: AppColors.caption,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StaffProfileAccessChip extends StatelessWidget {
  const _StaffProfileAccessChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StaffAdminUi.cardBorder),
      ),
      child: Text(
        label,
        style: AppTextStyle.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
