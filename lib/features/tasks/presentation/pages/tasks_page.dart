import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/constants/lms_resource_links.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Экран Мои курсы (LMS).
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool _loading = true;
  List<({String title, String url})> _resourceLinks = const [];

  static const _accentColors = [
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF7C3AED),
    Color(0xFFCA8A04),
    Color(0xFF059669),
  ];

  static const _icons = [
    Icons.menu_book_rounded,
    Icons.school_rounded,
    Icons.language_rounded,
    Icons.library_books_rounded,
    Icons.public_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final lmsRaw = await AppContainer.studentServicesApi.lmsList();
      final parsed = LmsResourceLinks.fromApi(lmsRaw);
      if (mounted) setState(() => _resourceLinks = parsed);
    } catch (_) {
      if (mounted) setState(() => _resourceLinks = const []);
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

  static String _hostLabel(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.startsWith('www.')) return host.substring(4);
    return host.isNotEmpty ? host : url;
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
              color: const Color(0xFF2563EB),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppUi.screenPaddingH,
                  12,
                  AppUi.screenPaddingH,
                  28,
                ),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  for (int i = 0; i < _resourceLinks.length; i++)
                    _ResourceLinkTile(
                      title: _resourceLinks[i].title,
                      subtitle: _hostLabel(_resourceLinks[i].url),
                      accentColor: _accentColors[i % _accentColors.length],
                      icon: _icons[i % _icons.length],
                      onTap: () => _openUrl(context, _resourceLinks[i].url),
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

class _ResourceLinkTile extends StatelessWidget {
  const _ResourceLinkTile({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                  color: accentColor,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: accentColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 1.25,
                                color: AppColors.notificationSubtitle,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
