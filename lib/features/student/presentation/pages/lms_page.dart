import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Внешние учебные ресурсы (фиксированные ссылки) и переход к РУП в приложении.
class LmsCredentialsPage extends StatelessWidget {
  const LmsCredentialsPage({super.key});

  static const List<({String title, String url})> _links = [
    (title: 'Юрайт', url: 'https://urait.ru/'),
    (title: 'ПРОФ СПО', url: 'https://profspo.ru/'),
    (title: 'Академия Москва', url: 'https://academia-moscow.ru/'),
  ];

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
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: Color(0xFF2563EB)),
                    title: Text(
                      'Учебный план (РУП)',
                      style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Данные из 1С в разделе «Оценки»',
                      style: AppTextStyle.inter(fontSize: 12, color: AppColors.notificationSubtitle),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/app/grades'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Электронные ресурсы',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._links.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
                      ),
                      child: ListTile(
                        title: Text(
                          e.title,
                          style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        subtitle: Text(
                          e.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.inter(fontSize: 12, color: AppColors.notificationSubtitle),
                        ),
                        trailing: const Icon(Icons.open_in_new_rounded, color: Color(0xFF2563EB)),
                        onTap: () => _openUrl(context, e.url),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
