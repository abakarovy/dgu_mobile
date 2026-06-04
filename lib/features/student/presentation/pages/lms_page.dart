import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/lms_resource_links.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/features/student/presentation/widgets/student_module_tile.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// «Мои курсы» — `GET /api/lms` (без локального списка ссылок).
class LmsCredentialsPage extends StatefulWidget {
  const LmsCredentialsPage({super.key});

  @override
  State<LmsCredentialsPage> createState() => _LmsCredentialsPageState();
}

class _LmsCredentialsPageState extends State<LmsCredentialsPage> {
  bool _loading = true;
  List<({String title, String url})> _links = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await AppContainer.studentServicesApi.lmsList();
      final parsed = LmsResourceLinks.fromApi(raw);
      if (mounted) setState(() => _links = parsed);
    } catch (_) {
      if (mounted) setState(() => _links = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    if (!await canLaunchUrl(u)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку')),
        );
      }
      return;
    }
    await launchUrl(u, mode: LaunchMode.externalApplication);
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
              headerTitle: Text('Мои курсы', style: appHeaderNestedTitleStyle),
            ),
            body: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _links.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: [
                            Icon(Icons.link_off_outlined, size: 48, color: AppColors.caption),
                            const SizedBox(height: 16),
                            Text(
                              'Список платформ пока не опубликован',
                              textAlign: TextAlign.center,
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            for (var i = 0; i < _links.length; i++)
                              StudentModuleTile(
                                icon: Icons.language_rounded,
                                title: _links[i].title,
                                subtitle: _links[i].url,
                                accentColor: const Color(0xFF2563EB),
                                onTap: () => _openUrl(context, _links[i].url),
                              ),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }
}
