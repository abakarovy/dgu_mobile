import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/staff/staff_module_navigation.dart';
import '../../../../data/models/staff_capabilities_model.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/staff_admin_ui.dart';

/// Раздел без нативного экрана — открыть на сайте.
class StaffWebModulePage extends StatelessWidget {
  const StaffWebModulePage({super.key, required this.moduleId});

  final String moduleId;

  Future<void> _openSite(BuildContext context) async {
    final url = StaffModuleNavigation.webAdminUrl(moduleId);
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = AppContainer.jsonCache.getJsonMap(StaffModuleNavigation.cacheKey);
    StaffModuleModel? module;
    if (caps != null && caps['modules'] is List) {
      for (final raw in caps['modules'] as List) {
        if (raw is Map && raw['id'] == moduleId) {
          module = StaffModuleModel.fromJson(Map<String, dynamic>.from(raw));
          break;
        }
      }
    }
    final label = module?.label ?? moduleId;

    return Scaffold(
      backgroundColor: StaffAdminUi.bg,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text(label, style: appHeaderNestedTitleStyle),
        showNotificationIcon: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppUi.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StaffAdminUi.pageTitle(label),
            const SizedBox(height: 12),
            StaffAdminUi.infoBanner(
              module?.note ??
                  'Расширенное редактирование доступно в полной версии админки на сайте.',
            ),
            const SizedBox(height: 24),
            StaffAdminUi.primaryButton(
              label: 'Открыть на сайте',
              icon: Icons.open_in_browser,
              onPressed: () => _openSite(context),
            ),
          ],
        ),
      ),
    );
  }
}
