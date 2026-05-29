import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/edu_disclosure_api.dart';
import '../../../../shared/widgets/app_header.dart';

/// Разделы сведений об ОО — как на college.dgu.ru/svedeniya.
abstract final class ApplicantDisclosureSections {
  static const entries = <({String id, String title})>[
    (id: 'basic', title: 'Основные сведения'),
    (id: 'structure', title: 'Структура и органы управления'),
    (id: 'documents', title: 'Документы'),
    (id: 'education', title: 'Образование'),
    (id: 'standards', title: 'Образовательные стандарты'),
    (id: 'staff', title: 'Педагогический состав'),
    (id: 'mto', title: 'Материально-техническое обеспечение'),
    (id: 'scholarship', title: 'Стипендии и меры поддержки'),
    (id: 'paid_services', title: 'Платные образовательные услуги'),
    (id: 'finance', title: 'Финансово-хозяйственная деятельность'),
    (id: 'vacant', title: 'Вакантные места для приёма'),
  ];
}

/// Список разделов сведений об образовательной организации.
class ApplicantDisclosurePage extends StatefulWidget {
  const ApplicantDisclosurePage({super.key});

  @override
  State<ApplicantDisclosurePage> createState() => _ApplicantDisclosurePageState();
}

class _ApplicantDisclosurePageState extends State<ApplicantDisclosurePage> {
  Map<String, dynamic> _data = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cached = AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey);
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() => _data = cached);
      }
      final fresh = await AppContainer.eduDisclosureApi.getDisclosure();
      await AppContainer.jsonCache.setJson(EduDisclosureApi.cacheKey, fresh);
      if (mounted) setState(() => _data = fresh);
    } catch (_) {
      final cached = AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey);
      if (cached != null && mounted) setState(() => _data = cached);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Сведения об ОО', style: appHeaderNestedTitleStyle),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: _load,
        child: _loading && _data.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppUi.screenPaddingH,
                  AppUi.spacingL,
                  AppUi.screenPaddingH,
                  30,
                ),
                children: [
                  Text(
                    'ФГБОУ ВО «ДГУ» — колледж',
                    style: AppTextStyle.inter(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.notificationSubtitle,
                    ),
                  ),
                  const SizedBox(height: AppUi.spacingL),
                  for (var i = 0; i < ApplicantDisclosureSections.entries.length; i++) ...[
                    _SectionTile(
                      title: ApplicantDisclosureSections.entries[i].title,
                      onTap: () => context.push(
                        '/login/applicant/svedeniya/${ApplicantDisclosureSections.entries[i].id}',
                        extra: _data,
                      ),
                    ),
                    if (i != ApplicantDisclosureSections.entries.length - 1)
                      const SizedBox(height: AppUi.spacingM),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppUi.radiusL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppUi.spacingL, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}

/// Содержимое одного раздела сведений.
class ApplicantDisclosureSectionPage extends StatelessWidget {
  const ApplicantDisclosureSectionPage({
    super.key,
    required this.sectionId,
    required this.data,
  });

  final String sectionId;
  final Map<String, dynamic> data;

  String get _title {
    for (final e in ApplicantDisclosureSections.entries) {
      if (e.id == sectionId) return e.title;
    }
    return 'Раздел';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text(_title, style: appHeaderNestedTitleStyle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppUi.screenPaddingH,
          AppUi.spacingL,
          AppUi.screenPaddingH,
          30,
        ),
        children: _DisclosureSectionBody(sectionId: sectionId, data: data).buildWidgets(),
      ),
    );
  }
}

class _DisclosureSectionBody {
  const _DisclosureSectionBody({required this.sectionId, required this.data});

  final String sectionId;
  final Map<String, dynamic> data;

  List<Widget> buildWidgets() {
    return switch (sectionId) {
      'basic' => _basic(),
      'structure' => _structure(),
      'documents' => _documents(),
      'education' => _education(),
      'standards' => _standards(),
      'staff' => _staff(),
      'mto' => _mto(),
      'scholarship' => _scholarship(),
      'paid_services' => _paidServices(),
      'finance' => _finance(),
      'vacant' => _vacant(),
      _ => [_empty('Раздел не найден')],
    };
  }

  List<Widget> _basic() {
    final basic = _map('basic');
    final founders = _map('basic_founders');
    final location = _map('basic_location_branches');
    final out = <Widget>[];

    void row(String label, String? value) {
      final w = _textBlock(label, value);
      if (w != null) out.add(w);
    }

    row('Дата создания образовательной организации', _str(basic['org_created_date']));
    row('Учредители', _str(basic['founders']));
    row('Место нахождения образовательной организации', _str(location['content'] ?? location['html']));
    row('Режим и график работы', _str(basic['work_schedule']));
    row('Контактные телефоны', _str(basic['phones']));
    row('Адреса электронной почты', _str(basic['email']));
    _appendHtml(out, _str(founders['body_html']));
    _appendHtml(out, _str(location['body_html']));

    if (out.isEmpty) out.add(_empty('Данные пока не опубликованы'));
    return out;
  }

  List<Widget> _structure() {
    final out = <Widget>[];
    _appendHtml(out, _str(_map('struktura_kollegzha')['body_html']));
    _appendExtended(out);
    final units = data['management_units'];
    if (units is List) {
      for (final raw in units) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        out.add(_card(
          title: _str(m['unit_name']) ?? 'Подразделение',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_str(m['head_full_name']) != null)
                _plain(_str(m['head_full_name'])!),
              if (_str(m['address']) != null) ...[
                const SizedBox(height: 6),
                _plain(_str(m['address'])!),
              ],
              if (_str(m['email']) != null) ...[
                const SizedBox(height: 6),
                _plain(_str(m['email'])!),
              ],
            ],
          ),
        ));
      }
    }
    if (out.isEmpty) out.add(_empty('Данные пока не опубликованы'));
    return out;
  }

  List<Widget> _documents() {
    final docs = data['documents'];
    final out = <Widget>[];
    if (docs is List) {
      for (final raw in docs) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final title = _str(m['title'] ?? m['label']) ?? 'Документ';
        final file = _str(m['file_rel'] ?? m['file_url'] ?? m['href']);
        out.add(_pdfTile(title: title, fileRel: file));
      }
    }
    if (out.isEmpty) out.add(_empty('Документы пока не опубликованы'));
    return out;
  }

  List<Widget> _education() {
    final edu = _map('education');
    final out = <Widget>[];
    _appendHtml(out, _str(edu['intro']));
    _appendHtml(out, _str(edu['levels_forms_normative']));
    _appendHtml(out, _str(edu['accreditation_terms']));
    _appendHtml(out, _str(edu['languages']));

    final programs = edu['programs'];
    if (programs is List) {
      for (final raw in programs) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        out.add(_card(
          title: _str(m['title'] ?? m['name']) ?? 'Программа',
          child: _html(_str(m['body_html'] ?? m['description']) ?? ''),
        ));
      }
    }

    final docs = data['education_program_documents'];
    if (docs is List && docs.isNotEmpty) {
      out.add(const SizedBox(height: AppUi.spacingM));
      out.add(_heading('Документы по программам'));
      for (final raw in docs) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        out.add(_pdfTile(
          title: _str(m['title'] ?? m['label']) ?? 'Документ',
          fileRel: _str(m['file_rel'] ?? m['file_url']),
        ));
      }
    }

    if (out.isEmpty) out.add(_empty('Данные пока не опубликованы'));
    return out;
  }

  List<Widget> _standards() {
    final out = <Widget>[];
    final standards = data['fgos_standards'];
    if (standards is List) {
      for (final raw in standards) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        out.add(_pdfTile(
          title: _str(m['title'] ?? m['label']) ?? 'Стандарт',
          fileRel: _str(m['file_rel'] ?? m['file_url'] ?? m['href']),
        ));
        _appendHtml(out, _str(m['body_html']));
      }
    }
    if (out.isEmpty) out.add(_empty('Стандарты пока не опубликованы'));
    return out;
  }

  List<Widget> _staff() {
    final out = <Widget>[];
    final staff = data['staff'];
    if (staff is List) {
      for (final raw in staff) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        out.add(_card(
          title: _str(m['full_name'] ?? m['name']) ?? 'Сотрудник',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_str(m['position']) != null) _plain(_str(m['position'])!),
              if (_str(m['subjects']) != null) ...[
                const SizedBox(height: 4),
                _plain(_str(m['subjects'])!),
              ],
              if (_str(m['education']) != null) ...[
                const SizedBox(height: 4),
                _plain(_str(m['education'])!),
              ],
            ],
          ),
        ));
      }
    }
    if (staff is! List) {
      _appendHtml(out, _str(_map('staff')['body_html']));
    }
    if (out.isEmpty) out.add(_empty('Сведения о составе пока не опубликованы'));
    return out;
  }

  List<Widget> _mto() => _tabsSection(_map('mto'), const [
        ('financial_support', 'Финансовое обеспечение'),
        ('cabinets', 'Материально-техническое обеспечение образовательного процесса'),
        ('practice_facilities', 'Материально-техническое обеспечение практики'),
        ('libraries', 'Библиотеки'),
        ('sport', 'Спорт'),
        ('meals', 'Средства обучения и воспитания'),
        ('health', 'Медицинское обслуживание'),
        ('info_systems', 'Информационные системы'),
      ]);

  List<Widget> _scholarship() {
    final s = _map('scholarship');
    final out = <Widget>[];
    _appendHtml(out, _str(s['scholarships']));
    _appendPdf(out, s['scholarships_pdf']);
    _appendHtml(out, _str(s['dormitory']));
    _appendPdf(out, s['dormitory_pdf']);
    _appendHtml(out, _str(s['employment']));
    _appendPdf(out, s['employment_pdf']);
    if (out.isEmpty) out.add(_empty('Данные пока не опубликованы'));
    return out;
  }

  List<Widget> _paidServices() {
    final p = _map('paid_services');
    final out = <Widget>[];
    _appendHtml(out, _str(p['procedure']));
    final files = p['contract_files'];
    if (files is List) {
      for (final raw in files) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        out.add(_pdfTile(
          title: _str(m['title'] ?? m['label']) ?? 'Документ',
          fileRel: _str(m['file_rel'] ?? m['file_url']),
        ));
      }
    }
    if (out.isEmpty) out.add(_empty('Данные пока не опубликованы'));
    return out;
  }

  List<Widget> _finance() {
    final f = _map('finance');
    final out = <Widget>[];
    _appendHtml(out, _str(f['activity_volume']));
    _appendHtml(out, _str(f['income_expense']));
    if (out.isEmpty) out.add(_empty('Данные пока не опубликованы'));
    return out;
  }

  List<Widget> _vacant() {
    final out = <Widget>[];
    _appendHtml(out, _str(_map('vacant')['admission_tables']));
    final seats = data['vacant_seats'];
    if (seats is List) {
      for (final raw in seats) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        out.add(_card(
          title: _str(m['program_name'] ?? m['title']) ?? 'Направление',
          child: _plain([
            if (_str(m['level']) != null) 'Уровень: ${_str(m['level'])}',
            if (_str(m['form']) != null) 'Форма: ${_str(m['form'])}',
            if (m['vacant_count'] != null) 'Вакантных мест: ${m['vacant_count']}',
          ].join('\n')),
        ));
      }
    }
    if (out.isEmpty) out.add(_empty('Данные пока не опубликованы'));
    return out;
  }

  List<Widget> _tabsSection(Map<String, dynamic> block, List<(String, String)> fields) {
    final out = <Widget>[];
    for (final (key, label) in fields) {
      final html = _str(block[key]);
      final pdf = block['${key}_pdf'];
      final tabs = block['${key}_tabs'];
      if (html != null && _hasMeaningfulHtml(html)) {
        out.add(_card(title: label, child: _html(html)));
      }
      _appendPdf(out, pdf, fallbackTitle: label);
      if (tabs is List) {
        for (final raw in tabs) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final tabTitle = _str(m['title']) ?? label;
          out.add(_card(
            title: tabTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_str(m['body_html']) != null) _html(_str(m['body_html'])!),
                if (m['pdfs'] is List)
                  for (final p in m['pdfs'] as List)
                    if (p is Map)
                      _pdfTile(
                        title: _str(p['link_title']) ?? tabTitle,
                        fileRel: _str(p['file_rel']),
                      ),
              ],
            ),
          ));
        }
      }
    }
    if (out.isEmpty) out.add(_empty('Данные пока не опубликованы'));
    return out;
  }

  void _appendExtended(List<Widget> out) {
    final ext = _map('svedeniya_extended');
    if (ext.isEmpty) return;
    final pdf = ext['struktura_samoobsledovanie_pdf'];
    if (pdf is Map) {
      final m = Map<String, dynamic>.from(pdf);
      out.add(_pdfTile(
        title: _str(m['title']) ?? 'Отчёт о самообследовании',
        fileRel: _str(m['href'] ?? m['file_rel']),
      ));
      if (_str(m['subtitle']) != null) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: _plain(_str(m['subtitle'])!),
        ));
      }
    }
    _appendHtml(out, _str(ext['struktura_psikholog_html']));
  }

  void _appendHtml(List<Widget> out, String? html) {
    if (!_hasMeaningfulHtml(html)) return;
    out.add(_html(html!));
    out.add(const SizedBox(height: AppUi.spacingM));
  }

  void _appendPdf(List<Widget> out, dynamic pdf, {String? fallbackTitle}) {
    if (pdf is! Map) return;
    final m = Map<String, dynamic>.from(pdf);
    final rel = _str(m['file_rel'] ?? m['href']);
    if (rel == null || rel.isEmpty) return;
    out.add(_pdfTile(
      title: _str(m['link_title']) ?? fallbackTitle ?? 'Документ PDF',
      fileRel: rel,
    ));
  }

  Map<String, dynamic> _map(String key) {
    final v = data[key];
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
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

  Widget? _textBlock(String label, String? value) {
    if (value == null) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUi.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.caption,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: AppTextStyle.inter(fontSize: 14, height: 1.4, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppUi.spacingM),
        child: Text(
          text,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _plain(String text) => SelectableText(
        text,
        style: AppTextStyle.inter(fontSize: 14, height: 1.4, color: AppColors.notificationSubtitle),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyle.inter(fontSize: 14, color: AppColors.caption),
          ),
        ),
      );

  Widget _card({required String title, required Widget child}) {
    return Padding(
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
  }

  Widget _html(String html) => Html(
        data: html,
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
        onLinkTap: (url, attributes, element) async {
          if (url == null || url.isEmpty) return;
          final resolved = url.startsWith('http')
              ? url
              : ApiConstants.resolvePortalHref(url);
          final u = Uri.tryParse(resolved);
          if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
        },
      );

  Widget _pdfTile({required String title, String? fileRel}) {
    if (fileRel == null || fileRel.isEmpty) return const SizedBox.shrink();
    final url = _resolveFile(fileRel);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUi.spacingM),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppUi.radiusM),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final u = Uri.tryParse(url);
            if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
          },
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

  static String _resolveFile(String rel) {
    if (rel.startsWith('http://') || rel.startsWith('https://')) return rel;
    if (rel.startsWith('/uploads/')) return ApiConstants.resolvePublicFileUrl(rel);
    if (rel.startsWith('/')) return ApiConstants.resolvePublicFileUrl(rel);
    return ApiConstants.resolvePublicFileUrl('/uploads/$rel');
  }
}
