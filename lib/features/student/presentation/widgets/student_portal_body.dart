import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/student/student_portal_constants.dart';
import 'package:dgu_mobile/core/student/student_portal_hub.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/data/svedeniya/svedeniya_merge.dart';
import 'package:flutter/material.dart';

import 'student_portal_department_blocks.dart';
import 'student_portal_html_renderer.dart';

/// Контент одного подраздела «Студентам» (`GET /api/student-portal` + при необходимости `svedeniya_extended`).
class StudentPortalBody extends StatelessWidget {
  const StudentPortalBody({
    super.key,
    required this.sectionId,
    required this.portal,
    this.svedeniyaExtended = const {},
    required this.onOpenUrl,
    required this.onOpenFile,
  });

  final String sectionId;
  final Map<String, dynamic> portal;
  final Map<String, dynamic> svedeniyaExtended;
  final Future<void> Function(String url) onOpenUrl;
  final Future<void> Function(String? rel) onOpenFile;

  static const Color _accentPortal = Color(0xFF2563EB);
  static const Color _accentPdf = Color(0xFFDC2626);
  static const Color _accentVpr = Color(0xFF0891B2);
  static const Color _accentLink = Color(0xFF4F46E5);

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  static Map<String, dynamic> _map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic v) {
    if (v is! List) return const [];
    return [
      for (final raw in v)
        if (raw is Map) Map<String, dynamic>.from(raw),
    ];
  }

  static bool _hasMeaningfulHtml(String? html) =>
      StudentPortalHtmlRenderer.hasMeaningfulContent(html);

  static String _resolveHref(String href) {
    if (href.startsWith('http://') || href.startsWith('https://')) return href;
    return ApiConstants.resolvePortalHref(href);
  }

  static String? _formatFileSize(dynamic bytes) {
    if (bytes is! num || bytes <= 0) return null;
    final b = bytes.toInt();
    if (b < 1024) return '$b Б';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} КБ';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  @override
  Widget build(BuildContext context) {
    final children = switch (sectionId) {
      StudentPortalConstants.overviewSectionId => _buildOverview(),
      StudentPortalConstants.scheduleSectionId => _buildSchedule(includeGia: true),
      StudentPortalConstants.sessionsSectionId => _buildSessions(),
      StudentPortalConstants.eresourcesSectionId => _buildEresources(),
      StudentPortalConstants.vprSectionId => _buildVpr(),
      _ => const <Widget>[],
    };

    if (children.isEmpty) {
      return _emptySection();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _emptySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'Раздел не опубликован или пока пуст',
        textAlign: TextAlign.center,
        style: AppTextStyle.inter(fontSize: 14, color: AppColors.notificationSubtitle),
      ),
    );
  }

  List<Widget> _buildOverview() {
    final out = <Widget>[];
    final overview = _map(portal['overview']);
    final html = _str(overview['body_html']);
    if (_hasMeaningfulHtml(html)) {
      out.add(_richHtml(html!, accent: _accentLink));
    }
    out.addAll(_hubLinkTiles(overview['hub_links']));
    return out;
  }

  List<Widget> _buildSchedule({required bool includeGia}) {
    final out = <Widget>[];
    final page = _map(portal['schedule_page']);
    final html = _str(page['body_html']);

    if (studentPortalHtmlOverridesPdfGrid(html)) {
      if (_hasMeaningfulHtml(html)) {
        out.add(_richHtml(html!, accent: _accentPortal));
      }
    } else {
      out.addAll(_semesterPdfTiles('schedule_semesters'));
    }

    if (includeGia) {
      out.add(
        StudentPortalDepartmentBlocks(
          extended: svedeniyaExtended,
          gia: true,
        ),
      );
    }

    return out;
  }

  List<Widget> _buildSessions() {
    final out = <Widget>[];
    final page = _map(portal['sessions']);
    final html = _str(page['body_html']);

    if (studentPortalHtmlOverridesPdfGrid(html)) {
      if (_hasMeaningfulHtml(html)) {
        out.add(_richHtml(html!, accent: _accentPortal));
      }
    } else {
      out.addAll(_semesterPdfTiles('sessions_semesters'));
    }

    out.add(
      StudentPortalDepartmentBlocks(
        extended: svedeniyaExtended,
        gia: false,
      ),
    );
    return out;
  }

  List<Widget> _buildEresources() {
    final er = _map(portal['eresources']);
    final html = _str(er['body_html']);
    if (!_hasMeaningfulHtml(html)) return const [];
    return [_richHtml(html!, accent: _accentPortal)];
  }

  List<Widget> _buildVpr() {
    final vpr = _map(portal['vpr']);
    if (vpr.isEmpty) return const [];

    final pageTitle = _str(vpr['page_title'] ?? vpr['title']);
    final bodyHtml = _str(vpr['body_html']);
    final fileUrl = _str(vpr['file_url']);

    final out = <Widget>[];
    if (pageTitle != null) {
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            pageTitle,
            style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      );
    }
    if (fileUrl != null) {
      final docTitle = _str(vpr['original_filename']) ?? pageTitle;
      if (docTitle != null) {
        out.add(
          _actionTile(
            accent: _accentVpr,
            icon: Icons.description_outlined,
            title: docTitle,
            subtitle: _formatFileSize(vpr['file_size']),
            onTap: () => onOpenFile(fileUrl),
          ),
        );
      }
    }
    if (_hasMeaningfulHtml(bodyHtml)) {
      out.add(_richHtml(bodyHtml!, accent: _accentVpr));
    }
    return out;
  }

  List<Widget> _hubLinkTiles(dynamic hub) {
    final links = StudentPortalHub.filtered(hub);
    return [
      for (final m in links)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _actionTile(
            accent: _accentLink,
            icon: m['external'] == true ? Icons.open_in_new_rounded : Icons.arrow_forward_rounded,
            title: _str(m['label'])!,
            onTap: () => onOpenUrl(_resolveHref(_str(m['href'])!)),
          ),
        ),
    ];
  }

  List<Widget> _semesterPdfTiles(String semestersKey) {
    final semesters = _listOfMaps(portal[semestersKey]);
    final tiles = <Widget>[];
    for (final sem in semesters) {
      final semTitle = _str(sem['title']);
      final entries = _listOfMaps(sem['entries']);
      if (entries.isNotEmpty) {
        if (semTitle != null) {
          tiles.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                semTitle,
                style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          );
        }
        for (final e in entries) {
          final label = _str(e['label'] ?? e['title']);
          final fileUrl = _str(e['file_url']);
          if (label == null || fileUrl == null) continue;
          tiles.add(
            _actionTile(
              accent: _accentPdf,
              icon: Icons.picture_as_pdf_outlined,
              title: label,
              subtitle: _formatFileSize(e['file_size']) ?? _str(e['original_filename']),
              onTap: () => onOpenFile(fileUrl),
            ),
          );
        }
      } else {
        final fileUrl = _str(sem['file_url']);
        final title = semTitle ?? _str(sem['label']);
        if (title != null && fileUrl != null) {
          tiles.add(
            _actionTile(
              accent: _accentPdf,
              icon: Icons.picture_as_pdf_outlined,
              title: title,
              subtitle: _formatFileSize(sem['file_size']),
              onTap: () => onOpenFile(fileUrl),
            ),
          );
        }
      }
    }
    return tiles;
  }

  Widget _richHtml(String html, {required Color accent}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: StudentPortalHtmlRenderer(
        html: html,
        onOpenUrl: onOpenUrl,
        linkAccent: accent,
      ),
    );
  }

  Widget _actionTile({
    required Color accent,
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                    color: accent,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: accent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTextStyle.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.25,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.inter(
                                    fontSize: 12,
                                    color: AppColors.notificationSubtitle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: AppColors.chevronRight, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
