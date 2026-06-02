import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_ui.dart';
import '../../core/theme/app_text_styles.dart';

/// Общие виджеты рендера сведений (HTML, PDF, внешние ссылки).
abstract final class SvedeniyaWidgets {
  static bool hasMeaningfulHtml(String? html) {
    if (html == null || html.trim().isEmpty) return false;
    final plain = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return plain.isNotEmpty;
  }

  static String? str(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  static String resolveFile(String rel) {
    if (rel.startsWith('http://') || rel.startsWith('https://')) return rel;
    if (rel.startsWith('/')) return ApiConstants.resolvePublicFileUrl(rel);
    return ApiConstants.resolvePublicFileUrl('/uploads/$rel');
  }

  static Future<void> openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u != null && await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  static Widget empty({String? hint}) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Text(
            hint ??
                'Для этого подраздела в API пока нет данных. '
                'Откройте полную версию на college.dgu.ru.',
            textAlign: TextAlign.center,
            style: AppTextStyle.inter(fontSize: 14, height: 1.4, color: AppColors.caption),
          ),
        ),
      );

  static Widget hiddenOnSite() => empty(
        hint: 'Раздел скрыт в настройках сайта (section_visibility).',
      );

  static Widget html(String data) => Html(
        data: data,
        shrinkWrap: true,
        style: {
          'body': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(14),
            fontFamily: 'Inter',
            color: AppColors.notificationSubtitle,
          ),
          'a': Style(color: AppColors.lightBlue),
          'p': Style(margin: Margins.only(bottom: 8)),
        },
        onLinkTap: (url, _, _) {
          if (url == null || url.isEmpty) return;
          final resolved = url.startsWith('http')
              ? url
              : ApiConstants.resolvePortalHref(url);
          openUrl(resolved);
        },
      );

  static Widget plain(String text) => SelectableText(
        text,
        style: AppTextStyle.inter(fontSize: 14, height: 1.4, color: AppColors.notificationSubtitle),
      );

  static Widget card({required String title, required Widget child}) => Padding(
        padding: const EdgeInsets.only(bottom: AppUi.spacingM),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppUi.spacingL),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppUi.radiusL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppUi.spacingM),
              child,
            ],
          ),
        ),
      );

  static Widget externalLinkTile({required String title, required String url, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUi.spacingM),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppUi.radiusM),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openUrl(url),
          child: Padding(
            padding: const EdgeInsets.all(AppUi.spacingM),
            child: Row(
              children: [
                const Icon(Icons.open_in_new, color: AppColors.lightBlue),
                const SizedBox(width: AppUi.spacingM),
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
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTextStyle.inter(
                            fontSize: 12,
                            color: AppColors.caption,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.chevronRight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget pdfTile({required String title, String? fileRel}) {
    if (fileRel == null || fileRel.isEmpty) return const SizedBox.shrink();
    final url = resolveFile(fileRel);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUi.spacingM),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppUi.radiusM),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openUrl(url),
          child: Padding(
            padding: const EdgeInsets.all(AppUi.spacingM),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626)),
                const SizedBox(width: AppUi.spacingM),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.open_in_new, size: 18, color: AppColors.chevronRight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void appendHtml(List<Widget> out, String? html) {
    if (!hasMeaningfulHtml(html)) return;
    out.add(SvedeniyaWidgets.html(html!));
    out.add(const SizedBox(height: AppUi.spacingM));
  }

  static void appendPdfSlot(List<Widget> out, dynamic pdf, {String? fallbackTitle}) {
    if (pdf is! Map) return;
    final m = Map<String, dynamic>.from(pdf);
    final rel = str(m['file_rel'] ?? m['file_url'] ?? m['href']);
    if (rel == null) return;
    out.add(pdfTile(
      title: str(m['link_title'] ?? m['title']) ?? fallbackTitle ?? 'Документ PDF',
      fileRel: rel,
    ));
  }

  static void appendPdfList(List<Widget> out, dynamic list) {
    if (list is! List) return;
    for (final raw in list) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final relRaw = m['file_rel'] ?? m['file_url'] ?? m['href'];
      if (relRaw == null) continue;
      final rel = str(relRaw);
      if (rel == null) continue;
      out.add(pdfTile(
        title: str(m['link_title'] ?? m['title'] ?? m['label']) ?? 'Документ',
        fileRel: rel,
      ));
    }
  }
}
