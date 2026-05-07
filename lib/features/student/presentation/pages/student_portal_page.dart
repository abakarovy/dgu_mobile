import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

/// Публичный снимок `/api/student-portal`: обзор, ссылки, PDF по семестрам, ВПР, ЭР.
class StudentPortalPage extends StatefulWidget {
  const StudentPortalPage({super.key});

  @override
  State<StudentPortalPage> createState() => _StudentPortalPageState();
}

class _StudentPortalPageState extends State<StudentPortalPage> {
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final m = await AppContainer.studentServicesApi.studentPortal();
      if (mounted) setState(() => _data = m);
    } catch (_) {}
    finally {
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

  bool _hasMeaningfulHtml(String? html) {
    if (html == null || html.trim().isEmpty) return false;
    final plain = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return plain.isNotEmpty;
  }

  Widget _htmlBlock(String html) {
    return Html(
      data: html,
      shrinkWrap: true,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(14),
          fontFamily: 'Inter',
          color: AppColors.grey,
        ),
        'a': Style(color: const Color(0xFF2563EB)),
        'h2': Style(
          fontSize: FontSize(17),
          fontWeight: FontWeight.w700,
          margin: Margins.only(bottom: 8),
        ),
        'h3': Style(
          fontSize: FontSize(15),
          fontWeight: FontWeight.w600,
          margin: Margins.only(bottom: 6),
        ),
        'p': Style(margin: Margins.only(bottom: 8)),
        'li': Style(margin: Margins.only(bottom: 4)),
        'ul': Style(margin: Margins.only(bottom: 8)),
      },
      onLinkTap: (url, attrs, el) {
        if (url == null || url.isEmpty) return;
        final resolved = url.startsWith('http://') || url.startsWith('https://')
            ? url
            : ApiConstants.resolvePortalHref(url);
        _openUrl(resolved);
      },
    );
  }

  Widget _htmlCard(String title, String html) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          _htmlBlock(html),
        ],
      ),
    );
  }

  List<Widget> _hubLinkTiles(Map<String, dynamic> overviewMap) {
    final hub = overviewMap['hub_links'];
    if (hub is! List) return [];
    final out = <Widget>[];
    for (final raw in hub) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final label = '${m['label'] ?? 'Ссылка'}';
      final href = m['href']?.toString() ?? '';
      if (href.isEmpty) continue;
      final external = m['external'] == true;
      final resolved =
          href.startsWith('http://') || href.startsWith('https://') ? href : ApiConstants.resolvePortalHref(href);
      out.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
          ),
          child: ListTile(
            leading: Icon(
              external ? Icons.open_in_new : Icons.article_outlined,
              color: const Color(0xFF4F46E5),
            ),
            title: Text(label, style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(
              resolved,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.inter(fontSize: 11, color: AppColors.notificationSubtitle),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _openUrl(resolved),
          ),
        ),
      );
    }
    return out;
  }

  List<Widget> _scheduleTiles() {
    final semesters = _data['schedule_semesters'];
    final list = semesters is List ? semesters : const <dynamic>[];
    final out = <Widget>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final semesterTitle = '${m['title'] ?? 'Семестр'}';
      final entries = m['entries'];
      if (entries is List && entries.isNotEmpty) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              semesterTitle,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
        for (final e in entries) {
          if (e is! Map) continue;
          final em = Map<String, dynamic>.from(e);
          final label = '${em['label'] ?? em['title'] ?? 'Документ'}';
          final origName = '${em['original_filename'] ?? ''}';
          final fileUrl = em['file_url']?.toString();
          out.add(
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
              ),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626)),
                title: Text(label, style: AppTextStyle.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: origName.isNotEmpty
                    ? Text(
                        origName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.inter(fontSize: 12, color: AppColors.notificationSubtitle),
                      )
                    : null,
                trailing: const Icon(Icons.open_in_new, size: 20),
                onTap: fileUrl == null || fileUrl.isEmpty ? null : () => _openFile(fileUrl),
              ),
            ),
          );
        }
      } else {
        final fileUrl = m['file_url']?.toString();
        if (fileUrl != null && fileUrl.isNotEmpty) {
          out.add(
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
              ),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626)),
                title: Text(semesterTitle),
                trailing: const Icon(Icons.open_in_new, size: 20),
                onTap: () => _openFile(fileUrl),
              ),
            ),
          );
        }
      }
    }
    return out;
  }

  List<Widget> _portalBodyChildren() {
    final children = <Widget>[];

    final overviewRaw = _data['overview'];
    Map<String, dynamic>? overviewMap;
    String? overviewLegacyStr;
    if (overviewRaw is Map) {
      overviewMap = Map<String, dynamic>.from(overviewRaw);
    } else if (overviewRaw is String && overviewRaw.trim().isNotEmpty) {
      overviewLegacyStr = overviewRaw.trim();
    }

    final overviewHtml = overviewMap != null ? overviewMap['body_html']?.toString() : null;

    if (overviewMap != null) {
      final hubTiles = _hubLinkTiles(overviewMap);
      if (hubTiles.isNotEmpty) {
        children.add(_heading('Разделы для студентов'));
        children.addAll(hubTiles);
      }
      if (_hasMeaningfulHtml(overviewHtml)) {
        children.add(const SizedBox(height: 4));
        children.add(_htmlCard('Важно', overviewHtml!));
      }
    } else if (overviewLegacyStr != null) {
      children.add(
        _sectionCard(
          child: Text(
            overviewLegacyStr,
            style: AppTextStyle.inter(fontSize: 14, height: 1.4, color: AppColors.grey),
          ),
        ),
      );
    }

    children.add(_heading('Расписание и документы'));
    final sched = _scheduleTiles();
    if (sched.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Нет прикреплённых файлов',
            style: AppTextStyle.inter(color: AppColors.notificationSubtitle, fontSize: 13),
          ),
        ),
      );
    } else {
      children.addAll(sched);
    }

    children.add(_heading('ВПР и материалы'));
    final vpr = _data['vpr'];
    if (vpr is Map) {
      final vm = Map<String, dynamic>.from(vpr);
      final pageTitle = '${vm['page_title'] ?? vm['title'] ?? 'ВПР'}';
      final bodyHtml = vm['body_html']?.toString();
      final fileUrl = vm['file_url']?.toString();
      final origName = '${vm['original_filename'] ?? ''}'.trim();

      children.add(
        Text(
          pageTitle,
          style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );

      if (fileUrl != null && fileUrl.isNotEmpty) {
        children.add(
          Card(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
            ),
            child: ListTile(
              leading: const Icon(Icons.attach_file, color: Color(0xFF0891B2)),
              title: Text(origName.isNotEmpty ? origName : 'Документ'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openFile(fileUrl),
            ),
          ),
        );
      }

      if (_hasMeaningfulHtml(bodyHtml)) {
        children.add(_htmlBlock(bodyHtml!));
      } else if (vm['items'] is List && (vm['items'] as List).isNotEmpty) {
        for (final it in (vm['items'] as List)) {
          if (it is! Map) continue;
          final im = Map<String, dynamic>.from(it);
          children.add(
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${im['title'] ?? 'Пункт'}'),
              ),
            ),
          );
        }
      } else if (fileUrl == null || fileUrl.isEmpty) {
        children.add(
          Text(
            'Пока нет текста или файлов в этом блоке',
            style: AppTextStyle.inter(color: AppColors.notificationSubtitle, fontSize: 13),
          ),
        );
      }
    } else {
      children.add(
        Text(
          'Нет данных раздела ВПР',
          style: AppTextStyle.inter(color: AppColors.notificationSubtitle, fontSize: 13),
        ),
      );
    }

    children.add(_heading('Электронные ресурсы'));
    final eresources = _data['eresources'];
    final resources = _data['digital_resources'];
    final resList = resources is List ? resources : const <dynamic>[];

    var anyER = false;
    if (eresources is Map) {
      final html = Map<String, dynamic>.from(eresources)['body_html']?.toString();
      if (_hasMeaningfulHtml(html)) {
        children.add(_htmlBlock(html!));
        anyER = true;
      }
    }

    for (final raw in resList) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final title = '${m['title'] ?? 'Ссылка'}';
      final url = '${m['url'] ?? ''}';
      children.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
          ),
          child: ListTile(
            leading: const Icon(Icons.link, color: Color(0xFF2563EB)),
            title: Text(title),
            subtitle:
                url.isNotEmpty ? Text(url, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
            onTap: url.isEmpty ? null : () => _openUrl(url),
          ),
        ),
      );
      anyER = true;
    }

    if (!anyER) {
      children.add(
        Text(
          'Нет опубликованного текста или ссылок в этом блоке',
          style: AppTextStyle.inter(color: AppColors.notificationSubtitle, fontSize: 13),
        ),
      );
    }

    return children;
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
            body: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _portalBodyChildren(),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text(t, style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 15)),
      );

  Widget _sectionCard({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.5)),
        ),
        child: child,
      );
}
