import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/student/student_portal_constants.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/features/student/presentation/widgets/student_portal_html_renderer.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Блоки по отделениям из `edu-disclosure` → `svedeniya_extended`.
class StudentPortalDepartmentBlocks extends StatelessWidget {
  const StudentPortalDepartmentBlocks({
    super.key,
    required this.extended,
    required this.gia,
  });

  final Map<String, dynamic> extended;
  final bool gia;

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  @override
  Widget build(BuildContext context) {
    final titleKey =
        gia ? 'studentam_gia_block_title' : 'studentam_sessions_block_title';
    final listKey = gia
        ? 'studentam_department_gia'
        : 'studentam_department_sessions';
    final title = _str(extended[titleKey]) ??
        (gia
            ? StudentPortalConstants.giaDepartmentTitleDefault
            : StudentPortalConstants.sessionsDepartmentTitleDefault);
    final list = extended[listKey];
    if (list is! List || list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final raw in list) ...[
            if (raw is Map) _departmentCard(context, Map<String, dynamic>.from(raw)),
          ],
        ],
      ),
    );
  }

  Widget _departmentCard(BuildContext context, Map<String, dynamic> dept) {
    final name = _str(dept['name']);
    final subKeys = gia
        ? const ['demo_exam', 'defense']
        : const ['exam_session', 'retake', 'commission'];

    final children = <Widget>[];
    for (final subKey in subKeys) {
      final subRaw = dept[subKey];
      if (subRaw is! Map) continue;
      final sub = Map<String, dynamic>.from(subRaw);
      final subTitle = _str(sub['title']) ?? subKey;
      final html = _str(sub['body_html']);
      final pdfs = sub['pdfs'];

      final inner = <Widget>[];
      if (StudentPortalHtmlRenderer.hasMeaningfulContent(html)) {
        inner.add(
          StudentPortalHtmlRenderer(
            html: html!,
            onOpenUrl: (url) => _openUrl(context, url),
          ),
        );
      }
      if (pdfs is List) {
        for (final p in pdfs) {
          if (p is! Map) continue;
          final pm = Map<String, dynamic>.from(p);
          final rel = _str(pm['file_rel'] ?? pm['file_url']);
          final pt = _str(pm['link_title'] ?? pm['title']) ?? 'Документ';
          if (rel == null) continue;
          inner.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _pdfRow(context, title: pt, fileRel: rel),
            ),
          );
        }
      }
      if (inner.isEmpty) continue;
      children.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppUi.spacingM),
          padding: const EdgeInsets.all(AppUi.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subTitle,
                style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...inner,
            ],
          ),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlue.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name != null) ...[
            Text(
              name,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _pdfRow(BuildContext context, {required String title, required String fileRel}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openFile(context, fileRel),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyle.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.chevronRight, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final resolved = url.startsWith('http')
        ? url
        : ApiConstants.resolvePortalHref(url);
    final u = Uri.tryParse(resolved);
    if (u != null && await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openFile(BuildContext context, String rel) async {
    final url = ApiConstants.resolvePublicFileUrl(rel);
    await _openUrl(context, url);
  }
}
