import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/student/student_portal_constants.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/data/api/edu_disclosure_api.dart';
import 'package:dgu_mobile/features/student/presentation/widgets/student_portal_body.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dgu_mobile/core/constants/api_constants.dart';

/// Портал «Студентам»: `GET /api/student-portal` + блоки отделений из `edu-disclosure`.
class StudentPortalPage extends StatefulWidget {
  const StudentPortalPage({super.key});

  @override
  State<StudentPortalPage> createState() => _StudentPortalPageState();
}

class _StudentPortalPageState extends State<StudentPortalPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _loadError;
  Map<String, dynamic> _portal = {};
  Map<String, dynamic> _extended = {};

  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: StudentPortalConstants.sectionTabs.length,
      vsync: this,
    );
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        AppContainer.studentServicesApi.studentPortal(),
        AppContainer.eduDisclosureApi.getDisclosure(),
      ]);
      final disclosure = results[1];
      final extRaw = disclosure['svedeniya_extended'];
      if (mounted) {
        setState(() {
          _portal = results[0];
          _extended = extRaw is Map
              ? Map<String, dynamic>.from(extRaw)
              : const {};
          _loadError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        final cached = AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey);
        final extRaw = cached?['svedeniya_extended'];
        setState(() {
          _portal = {};
          _extended =
              extRaw is Map ? Map<String, dynamic>.from(extRaw) : const {};
          _loadError = 'Не удалось загрузить данные портала';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u != null && await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openFile(String? rel) async {
    if (rel == null || rel.isEmpty) return;
    await _openUrl(ApiConstants.resolvePublicFileUrl(rel));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppHeader(
              leading: appHeaderNestedBackLeading(context),
              headerTitle: Text('Студентам', style: appHeaderNestedTitleStyle),
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabs,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          padding: const EdgeInsets.only(left: 10, right: 12),
                          labelPadding: const EdgeInsets.only(right: 14),
                          labelColor: AppColors.primaryBlue,
                          unselectedLabelColor: AppColors.notificationSubtitle,
                          indicatorColor: AppColors.primaryBlue,
                          labelStyle: AppTextStyle.inter(fontWeight: FontWeight.w600, fontSize: 13),
                          unselectedLabelStyle: AppTextStyle.inter(fontSize: 13),
                          tabs: [
                            for (final t in StudentPortalConstants.sectionTabs)
                              Tab(text: t.label),
                          ],
                        ),
                      ),
                      if (_loadError != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _errorBanner(_loadError!),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primaryBlue,
                          onRefresh: _load,
                          child: TabBarView(
                            controller: _tabs,
                            children: [
                              for (final t in StudentPortalConstants.sectionTabs)
                                ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 28),
                                  children: [
                                    StudentPortalBody(
                                      sectionId: t.id,
                                      portal: _portal,
                                      svedeniyaExtended: _extended,
                                      onOpenUrl: _openUrl,
                                      onOpenFile: _openFile,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyle.inter(fontSize: 13, color: const Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }
}
