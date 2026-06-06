import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/staff/staff_module_navigation.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/models/staff_capabilities_model.dart';
import '../widgets/staff_admin_ui.dart';
import '../widgets/staff_dashboard_widgets.dart';

/// Главная вкладка сотрудника — статистика админ-панели.
class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  Map<String, dynamic>? _stats;
  StaffCapabilitiesModel? _caps;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _caps = _readCachedCaps();
    unawaited(_load());
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

  bool get _canLoadDashboard {
    final caps = _caps;
    if (caps == null) return true;
    if (caps.canAccessSiteAdmin || caps.isAdmin) return true;
    return caps.modules.any((m) => m.id == 'dashboard');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final caps = await AppContainer.staffApi.getCapabilities();
      await AppContainer.jsonCache.setJson(StaffModuleNavigation.cacheKey, caps.toJson());
      _caps = caps;
    } catch (_) {}

    if (!_canLoadDashboard) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _stats = null;
      });
      return;
    }

    try {
      final stats = await AppContainer.staffModulesApi.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить статистику';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = _caps;
    final title = caps?.cabinetTitle ?? 'Сотрудник';

    if (_loading && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canLoadDashboard) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: StaffAdminUi.tabPaddingAll,
          children: [
            Text(
              title,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Статистика доступна администраторам. Рабочие разделы — во вкладке «Инструменты».',
              style: AppTextStyle.inter(
                fontSize: 15,
                height: 1.45,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null && _stats == null) {
      return Center(
        child: Padding(
          padding: StaffAdminUi.tabPaddingAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ColoredBox(
        color: StaffDashboardTheme.bg,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            StaffAdminUi.tabPaddingH,
            16,
            StaffAdminUi.tabPaddingH,
            32,
          ),
          children: [
            StaffDashboardView(
              stats: _stats ?? const {},
            ),
          ],
        ),
      ),
    );
  }
}
