import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/staff/staff_module_navigation.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/models/staff_capabilities_model.dart';
import '../../../../data/models/user_model.dart';
import '../widgets/staff_admin_ui.dart';
import '../widgets/staff_module_tile.dart';

/// Вкладка «Инструменты» — модули админки как на сайте.
class StaffToolsPage extends StatefulWidget {
  const StaffToolsPage({super.key});

  @override
  State<StaffToolsPage> createState() => _StaffToolsPageState();
}

class _StaffToolsPageState extends State<StaffToolsPage> {
  StaffCapabilitiesModel? _caps;
  bool _loading = true;
  String? _error;

  static const _excludedModuleIds = {'profile', 'dashboard', 'users'};

  /// Только эти разделы показываем во вкладке «Инструменты».
  static const _toolsWhitelist = {
    'news',
    'groups',
    'moderation',
    'weekly_grades',
    'scholarship_rating',
    'mobile_app',
  };

  static const _preferredOrder = [
    'news',
    'groups',
    'moderation',
    'weekly_grades',
    'scholarship_rating',
    'mobile_app',
  ];

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
    _caps = _readCached();
    if (_caps != null) _loading = false;
    _load();
  }

  StaffCapabilitiesModel? _readCached() {
    final raw = AppContainer.jsonCache.getJsonMap(StaffModuleNavigation.cacheKey);
    if (raw == null) return null;
    try {
      return StaffCapabilitiesModel.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final caps = await AppContainer.staffApi.getCapabilities();
      await AppContainer.jsonCache.setJson(StaffModuleNavigation.cacheKey, caps.toJson());
      if (!mounted) return;
      setState(() {
        _caps = caps;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_caps == null) _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_caps == null) _error = 'Не удалось загрузить разделы';
      });
    }
  }

  int _orderIndex(String id) {
    final i = _preferredOrder.indexOf(id);
    return i >= 0 ? i : 100 + id.hashCode.abs() % 50;
  }

  List<StaffModuleModel> _modules() {
    final caps = _caps;
    var modules = <StaffModuleModel>[];

    if (caps != null) {
      modules = caps.homeModules
          .where((m) => !_excludedModuleIds.contains(m.id))
          .map(
            (m) => StaffModuleModel(
              id: m.id,
              label: m.label,
              mobileReady: 'full',
              note: m.note,
            ),
          )
          .toList();
    }

    UserModel? user;
    final meRaw = AppContainer.jsonCache.getJsonMap('auth:me');
    if (meRaw != null) {
      try {
        user = UserModel.fromJson(meRaw);
      } catch (_) {}
    }

    final isAdmin = caps?.canAccessSiteAdmin == true ||
        caps?.isAdmin == true ||
        user?.canAccessSiteAdmin == true;

    if (isAdmin) {
      final ids = modules.map((m) => m.id).toSet();
      for (final d in _defaultAdminModules) {
        if (!ids.contains(d.id)) modules.add(d);
      }
    }

    modules = modules.where((m) => _toolsWhitelist.contains(m.id)).toList();

    if (modules.isEmpty) {
      return const [];
    }

    modules.sort((a, b) => _orderIndex(a.id).compareTo(_orderIndex(b.id)));
    return modules;
  }

  void _openModule(StaffModuleModel module) {
    final route = StaffModuleNavigation.nativeRouteFor(module);
    if (route != null) {
      if (route == '/staff/users' || route == '/staff/home' || route == '/staff/profile') {
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

  @override
  Widget build(BuildContext context) {
    final modules = _modules();

    if (_loading && _caps == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _caps == null) {
      return Center(
        child: Padding(
          padding: StaffAdminUi.tabPaddingAll,
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: modules.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: StaffAdminUi.tabPaddingAll,
              children: [
                Text(
                  'Нет доступных инструментов',
                  style: AppTextStyle.inter(color: AppColors.grey),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                StaffAdminUi.tabPaddingH,
                AppUi.spacingL,
                StaffAdminUi.tabPaddingH,
                32,
              ),
              itemCount: modules.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppUi.spacingM),
              itemBuilder: (context, index) {
                final module = modules[index];
                return StaffModuleTile(
                  module: module,
                  icon: StaffModuleNavigation.iconFor(module.id),
                  onTap: () => _openModule(module),
                );
              },
            ),
    );
  }
}
