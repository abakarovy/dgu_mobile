import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_ui.dart';
import '../../core/constants/college_public_links.dart';
import '../../core/student/student_portal_constants.dart';
import '../../core/student/student_portal_hub.dart';
import '../../data/svedeniya/svedeniya_merge.dart';
import '../../data/svedeniya/svedeniya_static_defaults.dart';
import 'edu_disclosure_nav.dart';
import 'svedeniya_widgets.dart';

/// Сборка экрана подраздела — паритет с SvedeniyaSectionBody + merge на клиенте.
class SvedeniyaContentBuilder {
  SvedeniyaContentBuilder({
    required this.rootId,
    required this.childId,
    required this.merged,
    this.upbringing = const {},
    this.studentPortal = const {},
  });

  final String rootId;
  final String childId;
  final MergedSvedeniyaPayload merged;
  final Map<String, dynamic> upbringing;
  final Map<String, dynamic> studentPortal;

  String get pathKey => EduDisclosureNav.pathKey(rootId, childId);

  Map<String, dynamic> get _ext => merged.extended;

  Map<String, dynamic> get _okollege => merged.okollege;

  List<Widget> build() {
    if (!merged.isPathPublished(pathKey)) {
      return [SvedeniyaWidgets.hiddenOnSite()];
    }

    final out = <Widget>[];
    switch (rootId) {
      case 'osnovnye-svedeniya':
        _buildOkollege(out, childId);
      case 'struktura':
        _buildStruktura(out, childId);
      case 'dokumenty':
        _buildDokumenty(out, childId);
      case 'obrazovanie':
        _buildObrazovanie(out, childId);
      case 'mto':
        _buildMto(out, childId);
      case 'stipendii':
        _buildStipendii(out, childId);
      case 'biblioteka-i-sport':
        _buildBibliotekaSport(out, childId);
      case 'vospitatelnaya-deyatelnost':
        _buildVospitanie(out, childId);
      case 'nauchnaya-zhizn':
        _buildNauka(out, childId);
      case 'pedagogam-resursy':
        _buildPedagogam(out, childId);
      case 'studentam':
        _buildStudentam(out, childId);
    }
    _appendMicroPosts(out, pathKey);
    if (out.isEmpty) return [SvedeniyaWidgets.empty()];
    return out;
  }

  Map<String, dynamic> _mapFrom(Map<String, dynamic> parent, String key) {
    final v = parent[key];
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }

  void _appendMicroPosts(List<Widget> out, String key) {
    final posts = _ext['micro_posts'];
    if (posts is! Map) return;
    final list = posts[key];
    if (list is! List || list.isEmpty) return;
    out.add(const SizedBox(height: AppUi.spacingL));
    out.add(SvedeniyaWidgets.card(
      title: 'Новости раздела',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final raw in list)
            if (raw is Map) ...[
              if (SvedeniyaWidgets.str(raw['title']) != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    SvedeniyaWidgets.str(raw['title'])!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              if (SvedeniyaWidgets.str(raw['body_plain']) != null)
                SvedeniyaWidgets.plain(SvedeniyaWidgets.str(raw['body_plain'])!),
              const SizedBox(height: AppUi.spacingM),
            ],
        ],
      ),
    ));
  }

  void _buildOkollege(List<Widget> out, String child) {
    final o = _okollege;
    switch (child) {
      case 'obshaya-informatsiya':
        final block = _mapFrom(o, 'obshaya_informatsiya');
        final eyebrow = SvedeniyaWidgets.str(block['eyebrow']);
        if (eyebrow != null) {
          out.add(SvedeniyaWidgets.plain(eyebrow));
        }
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(block['eyebrow_intro']));
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(block['main_html']));
      case 'data-sozdaniya':
        final block = _mapFrom(o, 'data_sozdaniya');
        final title = SvedeniyaWidgets.str(block['highlight_title']);
        if (title != null) out.add(SvedeniyaWidgets.plain(title));
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(block['highlight_body_html']));
        final docs = block['documents'];
        if (docs is List) {
          for (final raw in docs) {
            if (raw is! Map) continue;
            final m = Map<String, dynamic>.from(raw);
            final href = SvedeniyaWidgets.str(m['href']);
            final label = SvedeniyaWidgets.str(m['label']) ?? 'Документ';
            if (href != null) {
              out.add(SvedeniyaWidgets.externalLinkTile(
                title: label,
                url: href.startsWith('http') ? href : SvedeniyaWidgets.resolveFile(href),
              ));
            }
          }
        }
      case 'uchreditel':
        final html = SvedeniyaWidgets.str(o['uchreditel_html']);
        if (html != null && SvedeniyaWidgets.hasMeaningfulHtml(html)) {
          SvedeniyaWidgets.appendHtml(out, html);
        } else {
          SvedeniyaWidgets.appendHtml(out, SvedeniyaStaticDefaults.founderHtml);
        }
      case 'mestonakhozhdenie':
        final html = SvedeniyaWidgets.str(o['mestonakhozhdenie_html']);
        SvedeniyaWidgets.appendHtml(out, html ?? SvedeniyaStaticDefaults.locationHtml);
      case 'rezhim-grafik':
        final blocks = o['rezhim_grafik_blocks'];
        if (blocks is List) {
          for (final raw in blocks) {
            if (raw is! Map) continue;
            final m = Map<String, dynamic>.from(raw);
            final lines = m['lines'] ?? m['paragraphs'];
            final body = lines is List ? lines.map((e) => '$e').join('\n') : '';
            out.add(SvedeniyaWidgets.card(
              title: SvedeniyaWidgets.str(m['title']) ?? 'Режим работы',
              child: SvedeniyaWidgets.plain(body),
            ));
          }
        }
        out.add(SvedeniyaWidgets.externalLinkTile(
          title: 'Расписание занятий',
          url: '${ApiConstants.collegeSiteOrigin}/svedeniya/studentam/raspisanie-zanyatiy',
        ));
      case 'sotrudnichestvo':
        final block = _mapFrom(o, 'sotrudnichestvo');
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(block['main_html']));
        SvedeniyaWidgets.appendPdfList(out, block['bottom_documents']);
      case 'vypuskniki':
        final html = SvedeniyaWidgets.str(o['vypuskniki_html']);
        if (html != null && SvedeniyaWidgets.hasMeaningfulHtml(html)) {
          SvedeniyaWidgets.appendHtml(out, html);
        } else {
          out.add(SvedeniyaWidgets.plain(SvedeniyaStaticDefaults.vypusknikiPlaceholder));
        }
      case 'kontaktnaya-informatsiya':
        final block = _mapFrom(o, 'kontaktnaya_informatsiya');
        final lines = <String>[
          if (SvedeniyaWidgets.str(block['full_org_html']) != null)
            SvedeniyaWidgets.str(block['full_org_html'])!.replaceAll(RegExp(r'<[^>]*>'), ' ').trim(),
          if (SvedeniyaWidgets.str(block['short_org_name']) != null)
            '${block['short_prefix'] ?? ''} ${block['short_org_name']}'.trim(),
          if (block['postal_lines'] is List)
            ...(block['postal_lines'] as List).map((e) => '$e'),
          if (SvedeniyaWidgets.str(block['phone_display']) != null)
            'Тел.: ${block['phone_display']}',
          if (SvedeniyaWidgets.str(block['email']) != null) '${block['email']}',
        ];
        out.add(SvedeniyaWidgets.card(
          title: 'Контактная информация',
          child: SvedeniyaWidgets.plain(lines.where((e) => e.trim().isNotEmpty).join('\n')),
        ));
    }
  }

  void _buildStruktura(List<Widget> out, String child) {
    switch (child) {
      case 'struktura-kolledzha':
        _buildStrukturaKolledzha(out);
      case 'kadrovy-sostav':
        SvedeniyaWidgets.appendPdfList(out, _ext['struktura_kadrovy_cards']);
      case 'otchyot-o-samoobsledovanii':
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(_ext['struktura_samoobsledovanie_html']));
        SvedeniyaWidgets.appendPdfList(out, _ext['struktura_samoobsledovanie_pdfs']);
        SvedeniyaWidgets.appendPdfSlot(out, _ext['struktura_samoobsledovanie_pdf']);
      case 'psikhologo-pedagogicheskaya-sluzhba':
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(_ext['struktura_psikholog_html']));
        SvedeniyaWidgets.appendPdfList(out, _ext['struktura_psikholog_pdfs']);
      case 'besplatnaya-meditsinskaya-pomoshch':
        final html = SvedeniyaWidgets.str(_ext['struktura_med_html']);
        if (html != null && SvedeniyaWidgets.hasMeaningfulHtml(html)) {
          SvedeniyaWidgets.appendHtml(out, html);
        }
        SvedeniyaWidgets.appendPdfList(out, _ext['struktura_med_pdfs']);
      case 'kafedry':
        final k = _mapFrom(_ext, 'struktura_kafedry');
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(k['body_html']));
        final href = SvedeniyaWidgets.str(k['portal_href'] ?? k['href']);
        if (href != null) {
          out.add(SvedeniyaWidgets.externalLinkTile(title: 'Портал кафедр', url: href));
        }
        SvedeniyaWidgets.appendPdfSlot(out, k['curators_pdf']);
      case 'sostav-soveta-kolledzha':
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(_ext['struktura_sovet_kolledzha_html']));
        SvedeniyaWidgets.appendPdfSlot(out, _ext['struktura_sovet_kolledzha_pdf']);
      case 'sostav-uchebno-metodicheskogo-soveta-kolledzha':
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(_ext['struktura_ums_kolledzha_html']));
        SvedeniyaWidgets.appendPdfSlot(out, _ext['struktura_ums_kolledzha_pdf']);
    }
  }

  void _buildStrukturaKolledzha(List<Widget> out) {
    final sk = merged.strukturaKolledzha;
    final lead = SvedeniyaWidgets.str(sk['intro_lead']);
    final heading = SvedeniyaWidgets.str(sk['intro_heading']);
    if (lead != null) out.add(SvedeniyaWidgets.plain(lead));
    if (heading != null) {
      out.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(heading, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ));
    }

    final director = sk['director'];
    if (director is Map) {
      final d = Map<String, dynamic>.from(director);
      final lines = <String>[
        if (SvedeniyaWidgets.str(d['subtitle']) != null) d['subtitle']!,
        if (SvedeniyaWidgets.str(d['phone']) != null) 'Тел.: ${d['phone']}',
        if (SvedeniyaWidgets.str(d['email']) != null) d['email']!,
      ];
      out.add(SvedeniyaWidgets.card(
        title: '${SvedeniyaWidgets.str(d['role']) ?? 'Директор'}: ${SvedeniyaWidgets.str(d['name']) ?? ''}',
        child: SvedeniyaWidgets.plain(lines.join('\n')),
      ));
    }

    final deputies = sk['deputies'];
    if (deputies is List) {
      for (final raw in deputies) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        out.add(SvedeniyaWidgets.card(
          title: '${SvedeniyaWidgets.str(m['role']) ?? 'Заместитель'}: ${SvedeniyaWidgets.str(m['name']) ?? ''}',
          child: SvedeniyaWidgets.plain(SvedeniyaWidgets.str(m['description']) ?? ''),
        ));
      }
    }

    final chairHeading = SvedeniyaWidgets.str(sk['chair_carousel_heading']);
    if (chairHeading != null) {
      out.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(chairHeading, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ));
    }
    final chairHeads = sk['chair_heads'];
    if (chairHeads is List) {
      for (final raw in chairHeads) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        out.add(SvedeniyaWidgets.card(
          title: SvedeniyaWidgets.str(m['name']) ?? 'Заведующий кафедрой',
          child: SvedeniyaWidgets.plain([
            if (SvedeniyaWidgets.str(m['department']) != null) m['department']!,
            if (SvedeniyaWidgets.str(m['degree']) != null) m['degree']!,
          ].join('\n')),
        ));
      }
    }

    final deptHeading = SvedeniyaWidgets.str(sk['department_carousel_heading']);
    if (deptHeading != null) {
      out.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(deptHeading, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ));
    }
    final departmentHeads = sk['department_heads'];
    if (departmentHeads is List) {
      for (final raw in departmentHeads) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final lines = m['lines'];
        final body = lines is List ? lines.map((e) => '$e').join('\n') : '';
        out.add(SvedeniyaWidgets.card(
          title: SvedeniyaWidgets.str(m['name']) ?? 'Заведующий отделением',
          child: SvedeniyaWidgets.plain(body),
        ));
      }
    }

    final units = merged.managementUnits;
    if (units.isNotEmpty) {
      out.add(const SizedBox(height: AppUi.spacingM));
      for (final raw in units) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final unitChildren = <Widget>[
          if (SvedeniyaWidgets.str(m['head_full_name']) != null)
            SvedeniyaWidgets.plain(SvedeniyaWidgets.str(m['head_full_name'])!),
          if (SvedeniyaWidgets.str(m['address']) != null) ...[
            const SizedBox(height: 6),
            SvedeniyaWidgets.plain(SvedeniyaWidgets.str(m['address'])!),
          ],
          if (SvedeniyaWidgets.str(m['email']) != null) ...[
            const SizedBox(height: 6),
            SvedeniyaWidgets.plain(SvedeniyaWidgets.str(m['email'])!),
          ],
        ];
        final regUrl = SvedeniyaWidgets.str(m['regulation_file_url']);
        if (regUrl != null) {
          unitChildren.add(SvedeniyaWidgets.pdfTile(title: 'Положение', fileRel: regUrl));
        }
        out.add(SvedeniyaWidgets.card(
          title: SvedeniyaWidgets.str(m['unit_name']) ?? 'Подразделение',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: unitChildren),
        ));
      }
    }
  }

  void _buildDokumenty(List<Widget> out, String child) {
    switch (child) {
      case 'katalog':
        out.add(SvedeniyaWidgets.externalLinkTile(
          title: 'Каталог нормативных документов',
          url: CollegePublicLinks.ndocJurkolUrl,
          subtitle: CollegePublicLinks.ndocJurkolUrl,
        ));
      case 'arhiv':
        final docs = merged.documents;
        var hasDocs = false;
        for (final raw in docs) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final title = SvedeniyaWidgets.str(m['title'] ?? m['label']) ?? 'Документ';
          final file = SvedeniyaWidgets.str(m['file_url'] ?? m['file_rel'] ?? m['href']);
          if (file != null) {
            hasDocs = true;
            out.add(SvedeniyaWidgets.pdfTile(title: title, fileRel: file));
          }
        }
        if (!hasDocs) {
          out.add(SvedeniyaWidgets.plain(
            'Файловый архив на сайте колледжа пока пуст. '
            'Нормативные документы доступны во внешнем каталоге.',
          ));
        }
        out.add(SvedeniyaWidgets.externalLinkTile(
          title: 'Каталог на ndoc.dgu.ru',
          url: CollegePublicLinks.ndocJurkolUrl,
        ));
    }
  }

  void _buildObrazovanie(List<Widget> out, String child) {
    if (child == 'sveden-dgu') {
      out.add(SvedeniyaWidgets.externalLinkTile(
        title: 'Сведения об образовании (ДГУ)',
        url: CollegePublicLinks.educationDguUrl,
        subtitle: CollegePublicLinks.educationDguUrl,
      ));
    }
  }

  void _buildMto(List<Widget> out, String child) {
    final field = MtoNav.fieldByChild[child];
    if (field == null) return;
    final mto = merged.mto;
    final html = SvedeniyaWidgets.str(mto[field]);
    final sectionTitle =
        EduDisclosureNav.childById('mto', child)?.title ?? child;
    if (html != null && SvedeniyaWidgets.hasMeaningfulHtml(html)) {
      out.add(SvedeniyaWidgets.card(title: sectionTitle, child: SvedeniyaWidgets.html(html)));
    }
    SvedeniyaWidgets.appendPdfSlot(out, mto['${field}_pdf'], fallbackTitle: field);
    final tabs = mto['${field}_tabs'];
    if (tabs is List) {
      for (final raw in tabs) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final tabTitle = SvedeniyaWidgets.str(m['title']) ?? field;
        final children = <Widget>[];
        SvedeniyaWidgets.appendHtml(children, SvedeniyaWidgets.str(m['body_html']));
        SvedeniyaWidgets.appendPdfList(children, m['pdfs']);
        if (children.isNotEmpty) {
          out.add(SvedeniyaWidgets.card(title: tabTitle, child: Column(children: children)));
        }
      }
    }
  }

  void _buildStipendii(List<Widget> out, String child) {
    if (child != 'podderzhka') return;
    out.add(SvedeniyaWidgets.externalLinkTile(
      title: 'Стипендии и меры поддержки (ДГУ)',
      url: CollegePublicLinks.dguSvedenGrantsUrl,
    ));
    final benefits = _ext['stipendii_social_benefits'];
    if (benefits is Map) {
      final m = Map<String, dynamic>.from(benefits);
      final href = SvedeniyaWidgets.str(m['href']);
      if (href != null) {
        out.add(SvedeniyaWidgets.externalLinkTile(
          title: SvedeniyaWidgets.str(m['label']) ?? 'Социальные льготы',
          url: href.startsWith('http') ? href : SvedeniyaWidgets.resolveFile(href),
        ));
      }
    }
  }

  void _buildBibliotekaSport(List<Widget> out, String child) {
    switch (child) {
      case 'biblioteka':
        out.add(SvedeniyaWidgets.externalLinkTile(
          title: 'Электронная библиотека ДГУ',
          url: CollegePublicLinks.libraryElibUrl,
        ));
        out.add(SvedeniyaWidgets.externalLinkTile(
          title: 'ЭБС «Юрайт»',
          url: CollegePublicLinks.libraryUraitUrl,
        ));
        out.add(SvedeniyaWidgets.externalLinkTile(
          title: 'Интернет-ресурсы',
          url: '${ApiConstants.collegeSiteOrigin}/svedeniya/studentam/elektronnye-resursy',
        ));
      case 'sportkompleks':
        out.add(SvedeniyaWidgets.card(
          title: 'Спорткомплекс',
          child: SvedeniyaWidgets.plain(SvedeniyaStaticDefaults.sportkompleksPlaceholder),
        ));
    }
  }

  void _buildVospitanie(List<Widget> out, String child) {
    final catKey = VospitanieNav.categoryByChild[child];
    if (catKey == null) return;
    final categories = upbringing['categories'];
    if (categories is! List) return;
    for (final raw in categories) {
      if (raw is! Map) continue;
      final cat = Map<String, dynamic>.from(raw);
      if (cat['key'] != catKey) continue;
      final entries = cat['entries'];
      if (entries is! List) return;
      for (final e in entries) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final title = SvedeniyaWidgets.str(m['title']) ?? 'Материал';
        final file = SvedeniyaWidgets.str(m['file_url']);
        if (file != null) {
          out.add(SvedeniyaWidgets.pdfTile(title: title, fileRel: file));
        }
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(m['body_html']));
      }
      return;
    }
  }

  void _buildNauka(List<Widget> out, String child) {
    switch (child) {
      case 'chempionat-professionaly':
        final block = _mapFrom(_ext, 'nauchnaya_chempionat');
        SvedeniyaWidgets.appendPdfList(out, block['documents']);
        final diary = block['diary'];
        if (diary is List) {
          for (final raw in diary) {
            if (raw is! Map) continue;
            final m = Map<String, dynamic>.from(raw);
            out.add(SvedeniyaWidgets.card(
              title: SvedeniyaWidgets.str(m['title']) ?? 'Мероприятие',
              child: SvedeniyaWidgets.plain(SvedeniyaWidgets.str(m['caption']) ?? ''),
            ));
          }
        }
      case 'nauchnye-kruzhki':
        final block = _mapFrom(_ext, 'nauchnaya_kruzhki');
        final html = SvedeniyaWidgets.str(block['body_html']);
        final plain = SvedeniyaWidgets.str(block['body_plain']);
        if (html != null && SvedeniyaWidgets.hasMeaningfulHtml(html)) {
          SvedeniyaWidgets.appendHtml(out, html);
        } else if (plain != null) {
          out.add(SvedeniyaWidgets.plain(plain));
        }
      case 'konkursy-i-olimpiady':
        final block = _mapFrom(_ext, 'nauchnaya_olimpiady');
        final html = SvedeniyaWidgets.str(block['body_html']);
        final plain = SvedeniyaWidgets.str(block['body_plain']);
        if (html != null && SvedeniyaWidgets.hasMeaningfulHtml(html)) {
          SvedeniyaWidgets.appendHtml(out, html);
        } else if (plain != null) {
          out.add(SvedeniyaWidgets.plain(plain));
        }
    }
  }

  void _buildPedagogam(List<Widget> out, String child) {
    if (child != 'vneshnie-ssylki') return;
    for (final raw in SvedeniyaStaticDefaults.teacherLinks) {
      final m = Map<String, dynamic>.from(raw);
      final href = SvedeniyaWidgets.str(m['href']);
      if (href == null) continue;
      out.add(SvedeniyaWidgets.externalLinkTile(
        title: SvedeniyaWidgets.str(m['label']) ?? 'Ссылка',
        url: href,
      ));
    }
  }

  void _appendStudentHubLinks(
    List<Widget> out, {
    bool Function(Map<String, dynamic> link)? include,
  }) {
    final overview = _mapFrom(studentPortal, 'overview');
    for (final m in StudentPortalHub.filtered(overview['hub_links'])) {
      if (include != null && !include(m)) continue;
      final href = SvedeniyaWidgets.str(m['href']);
      final label = SvedeniyaWidgets.str(m['label']);
      if (href == null || label == null) continue;
      final url = href.startsWith('http')
          ? href
          : '${ApiConstants.collegeSiteOrigin}$href';
      out.add(SvedeniyaWidgets.externalLinkTile(title: label, url: url));
    }
  }

  void _buildStudentam(List<Widget> out, String child) {
    switch (child) {
      case 'razdel':
        final overview = _mapFrom(studentPortal, 'overview');
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(overview['body_html']));
        _appendStudentHubLinks(out);
      case 'raspisanie-zanyatiy':
        _studentSchedule(out, 'schedule_page', 'schedule_semesters');
        _appendDepartmentGia(out);
      case 'raspisanie-sessiy':
        _studentSchedule(out, 'sessions', 'sessions_semesters');
        _appendDepartmentSessions(out);
      case 'elektronnye-resursy':
        final er = _mapFrom(studentPortal, 'eresources');
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(er['body_html']));
      case 'vpr':
        final vpr = _mapFrom(studentPortal, 'vpr');
        final title = SvedeniyaWidgets.str(vpr['page_title'] ?? vpr['title']);
        if (title != null) out.add(SvedeniyaWidgets.plain(title));
        SvedeniyaWidgets.appendHtml(out, SvedeniyaWidgets.str(vpr['body_html']));
        SvedeniyaWidgets.appendPdfSlot(out, {'file_url': vpr['file_url']});
        for (final m in _listMaps(vpr['items'])) {
          final itemTitle = SvedeniyaWidgets.str(m['title']);
          final rel = SvedeniyaWidgets.str(m['file_url']);
          final url = SvedeniyaWidgets.str(m['url'] ?? m['href']);
          if (itemTitle == null) continue;
          if (rel != null) {
            SvedeniyaWidgets.appendPdfSlot(out, {'file_url': rel, 'link_title': itemTitle});
          } else if (url != null) {
            final resolved = url.startsWith('http') ? url : '${ApiConstants.collegeSiteOrigin}$url';
            out.add(SvedeniyaWidgets.externalLinkTile(title: itemTitle, url: resolved));
          }
        }
      case 'sno':
        _appendStudentHubLinks(
          out,
          include: (m) {
            final label = (SvedeniyaWidgets.str(m['label']) ?? '').toLowerCase();
            final href = (SvedeniyaWidgets.str(m['href']) ?? '').toLowerCase();
            return label.contains('сно') || href.contains('sno');
          },
        );
    }
  }

  List<Map<String, dynamic>> _listMaps(dynamic v) {
    if (v is! List) return const [];
    return [
      for (final raw in v)
        if (raw is Map) Map<String, dynamic>.from(raw),
    ];
  }

  void _studentSchedule(List<Widget> out, String pageKey, String semestersKey) {
    final page = _mapFrom(studentPortal, pageKey);
    final html = SvedeniyaWidgets.str(page['body_html']);
    if (studentPortalHtmlOverridesPdfGrid(html)) {
      SvedeniyaWidgets.appendHtml(out, html);
      return;
    }
    final semesters = studentPortal[semestersKey];
    if (semesters is! List) return;
    for (final raw in semesters) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final semTitle = SvedeniyaWidgets.str(m['title']);
      final entries = m['entries'];
      if (entries is List) {
        for (final e in entries) {
          if (e is! Map) continue;
          final em = Map<String, dynamic>.from(e);
          final entryTitle = SvedeniyaWidgets.str(em['label'] ?? em['title']) ?? semTitle;
          if (entryTitle == null) continue;
          out.add(SvedeniyaWidgets.pdfTile(
            title: entryTitle,
            fileRel: SvedeniyaWidgets.str(em['file_url']),
          ));
        }
      } else {
        final title = semTitle ?? SvedeniyaWidgets.str(m['label']);
        if (title != null) {
          out.add(SvedeniyaWidgets.pdfTile(
            title: title,
            fileRel: SvedeniyaWidgets.str(m['file_url']),
          ));
        }
      }
    }
  }

  void _appendDepartmentSessions(List<Widget> out) {
    final title = SvedeniyaWidgets.str(_ext['studentam_sessions_block_title']) ??
        StudentPortalConstants.sessionsDepartmentTitleDefault;
    final list = _ext['studentam_department_sessions'];
    _appendDepartmentBlocks(out, title, list);
  }

  void _appendDepartmentGia(List<Widget> out) {
    final title = SvedeniyaWidgets.str(_ext['studentam_gia_block_title']) ??
        StudentPortalConstants.giaDepartmentTitleDefault;
    final list = _ext['studentam_department_gia'];
    _appendDepartmentBlocks(out, title, list);
  }

  void _appendDepartmentBlocks(List<Widget> out, String blockTitle, dynamic list) {
    if (list is! List || list.isEmpty) return;
    out.add(const SizedBox(height: AppUi.spacingL));
    final inner = <Widget>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final dept = Map<String, dynamic>.from(raw);
      if (SvedeniyaWidgets.str(dept['name']) != null) {
        inner.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            SvedeniyaWidgets.str(dept['name'])!,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ));
      }
      for (final subKey in ['exam_session', 'retake', 'commission', 'demo_exam', 'defense']) {
        final subRaw = dept[subKey];
        if (subRaw is! Map) continue;
        final sub = Map<String, dynamic>.from(subRaw);
        final subChildren = <Widget>[];
        SvedeniyaWidgets.appendHtml(subChildren, SvedeniyaWidgets.str(sub['body_html']));
        SvedeniyaWidgets.appendPdfList(subChildren, sub['pdfs']);
        if (subChildren.isNotEmpty) {
          inner.add(SvedeniyaWidgets.card(
            title: SvedeniyaWidgets.str(sub['title']) ?? subKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: subChildren),
          ));
        }
      }
      inner.add(const SizedBox(height: AppUi.spacingM));
    }
    out.add(SvedeniyaWidgets.card(title: blockTitle, child: Column(children: inner)));
  }
}
