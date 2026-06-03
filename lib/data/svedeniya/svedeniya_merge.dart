import 'svedeniya_static_defaults.dart';

/// Результат merge как на сайте: API + клиентские дефолты.
class MergedSvedeniyaPayload {
  const MergedSvedeniyaPayload({
    required this.raw,
    required this.extended,
    required this.okollege,
    required this.strukturaKolledzha,
  });

  final Map<String, dynamic> raw;
  final Map<String, dynamic> extended;
  final Map<String, dynamic> okollege;
  final Map<String, dynamic> strukturaKolledzha;

  Map<String, dynamic> get mto => _asMap(raw['mto']);

  List<dynamic> get documents {
    final v = raw['documents'];
    return v is List ? v : const [];
  }

  List<dynamic> get managementUnits {
    final v = raw['management_units'];
    return v is List ? v : const [];
  }

  bool isPathPublished(String pathKey) {
    final vis = extended['section_visibility'];
    if (vis is! Map) return true;
    return vis[pathKey] != false;
  }

  static MergedSvedeniyaPayload fromApi(Map<String, dynamic> raw) {
    final ext = _mergeExtended(_asMap(raw['svedeniya_extended']));
    final okollege = _mergeOkollege(_asMap(ext['okollege_svedeniya']));
    ext['okollege_svedeniya'] = okollege;

    final sk = _mergeStrukturaKolledzha(_asMap(raw['struktura_kolledzha']));

    return MergedSvedeniyaPayload(
      raw: raw,
      extended: ext,
      okollege: okollege,
      strukturaKolledzha: sk,
    );
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return {};
}

String? _coalesceStr(dynamic api, dynamic def) {
  final a = api?.toString().trim();
  if (a != null && a.isNotEmpty) return a;
  final d = def?.toString().trim();
  return (d != null && d.isNotEmpty) ? d : null;
}

List<dynamic>? _coalesceList(List<dynamic>? api, List<dynamic>? def) {
  if (api != null && api.isNotEmpty) return api;
  if (def != null && def.isNotEmpty) return def;
  return null;
}

Map<String, dynamic> _mergeExtended(Map<String, dynamic> api) {
  final out = Map<String, dynamic>.from(api);
  final social = _asMap(api['stipendii_social_benefits']);
  if (social.isEmpty) {
    out['stipendii_social_benefits'] =
        Map<String, dynamic>.from(SvedeniyaStaticDefaults.stipendiiSocialBenefitsDefault);
  } else {
    out['stipendii_social_benefits'] = {
      'label': _coalesceStr(
            social['label'],
            SvedeniyaStaticDefaults.stipendiiSocialBenefitsDefault['label'],
          ) ??
          'Социальные льготы',
      'href': _coalesceStr(
            social['href'],
            SvedeniyaStaticDefaults.stipendiiSocialBenefitsDefault['href'],
          ) ??
          '',
    };
  }
  return out;
}

Map<String, dynamic> _mergeOkollege(Map<String, dynamic> api) {
  final def = SvedeniyaStaticDefaults.okollegeDefaults;
  final out = <String, dynamic>{};

  final defObshaya = _asMap(def['obshaya_informatsiya']);
  final apiObshaya = _asMap(api['obshaya_informatsiya']);
  out['obshaya_informatsiya'] = {
    'eyebrow': _coalesceStr(apiObshaya['eyebrow'], defObshaya['eyebrow'] as String?),
    'eyebrow_intro': _coalesceStr(apiObshaya['eyebrow_intro'], defObshaya['eyebrow_intro'] as String?),
    'main_html': _coalesceStr(apiObshaya['main_html'], defObshaya['main_html'] as String?),
  };

  final defData = _asMap(def['data_sozdaniya']);
  final apiData = _asMap(api['data_sozdaniya']);
  out['data_sozdaniya'] = {
    'eyebrow': _coalesceStr(apiData['eyebrow'], defData['eyebrow'] as String?),
    'eyebrow_intro': _coalesceStr(apiData['eyebrow_intro'], defData['eyebrow_intro'] as String?),
    'highlight_title': _coalesceStr(apiData['highlight_title'], defData['highlight_title'] as String?),
    'highlight_body_html':
        _coalesceStr(apiData['highlight_body_html'], defData['highlight_body_html'] as String?),
    'documents': _coalesceList(
          apiData['documents'] is List ? List<dynamic>.from(apiData['documents'] as List) : null,
          List<dynamic>.from(defData['documents'] as List),
        ) ??
        [],
  };

  out['uchreditel_html'] = _coalesceStr(
    api['uchreditel_html'],
    def['uchreditel_html'] as String?,
  );

  out['mestonakhozhdenie_html'] = _coalesceStr(
    api['mestonakhozhdenie_html'],
    def['mestonakhozhdenie_html'] as String?,
  );

  out['rezhim_grafik_blocks'] = _coalesceList(
        api['rezhim_grafik_blocks'] is List
            ? List<dynamic>.from(api['rezhim_grafik_blocks'] as List)
            : null,
        List<dynamic>.from(def['rezhim_grafik_blocks'] as List),
      ) ??
      [];

  final defSotr = _asMap(def['sotrudnichestvo']);
  final apiSotr = _asMap(api['sotrudnichestvo']);
  out['sotrudnichestvo'] = {
    'eyebrow': _coalesceStr(apiSotr['eyebrow'], defSotr['eyebrow'] as String?),
    'eyebrow_intro': _coalesceStr(apiSotr['eyebrow_intro'], defSotr['eyebrow_intro'] as String?),
    'main_html': _coalesceStr(apiSotr['main_html'], defSotr['main_html'] as String?),
    'bottom_documents': _coalesceList(
          apiSotr['bottom_documents'] is List
              ? List<dynamic>.from(apiSotr['bottom_documents'] as List)
              : null,
          List<dynamic>.from(defSotr['bottom_documents'] as List),
        ) ??
        [],
  };

  out['vypuskniki_html'] = _coalesceStr(api['vypuskniki_html'], def['vypuskniki_html'] as String?);

  final defKont = _asMap(def['kontaktnaya_informatsiya']);
  final apiKont = _asMap(api['kontaktnaya_informatsiya']);
  out['kontaktnaya_informatsiya'] = {
    for (final key in {
      'card_eyebrow',
      'full_org_html',
      'short_prefix',
      'short_org_name',
      'phone_display',
      'phone_href',
      'email',
    })
      key: _coalesceStr(apiKont[key], defKont[key] as String?),
    'postal_lines': _coalesceList(
          apiKont['postal_lines'] is List
              ? List<dynamic>.from(apiKont['postal_lines'] as List)
              : null,
          List<dynamic>.from(defKont['postal_lines'] as List),
        ) ??
        [SvedeniyaStaticDefaults.address],
  };

  return out;
}

Map<String, dynamic> _mergeStrukturaKolledzha(Map<String, dynamic> api) {
  if (api.isEmpty) return api;
  return api;
}

/// Паритет `studentPortalHtmlOverridesPdfGrid` — studentPortalHtml.ts:17
bool studentPortalHtmlOverridesPdfGrid(String? html) {
  if (html == null || html.trim().isEmpty) return false;
  final hasImg = RegExp(r'<img\b', caseSensitive: false).hasMatch(html);
  final plain = html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('&nbsp;', ' ')
      .trim()
      .toLowerCase();
  if (plain.isEmpty) return false;
  const placeholders = [
    'здесь будет размещено расписание занятий.',
    'здесь будет размещено расписание сессий.',
  ];
  if (placeholders.contains(plain)) return false;
  return hasImg || plain.isNotEmpty;
}
