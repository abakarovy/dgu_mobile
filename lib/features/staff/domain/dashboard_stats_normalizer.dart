/// Приводит ответ `/admin/dashboard-stats` к ключам, которые ждёт UI.
Map<String, dynamic> normalizeDashboardStats(Map<String, dynamic> raw) {
  final clients = raw['clients'] is Map
      ? Map<String, dynamic>.from(raw['clients'] as Map)
      : <String, dynamic>{};

  dynamic pick(String topKey, String nestedKey) =>
      raw[topKey] ?? clients[nestedKey];

  List<dynamic>? pickList(String topKey, String nestedKey) {
    final v = pick(topKey, nestedKey);
    return v is List ? v : null;
  }

  return {
    ...raw,
    'clients': clients,
    if (raw['department_heads_count'] == null && raw['department_staff_count'] != null)
      'department_heads_count': raw['department_staff_count'],
    'registrations_by_source_week': pickList(
      'registrations_by_source_week',
      'registrations_week_by_source',
    ),
    'registrations_by_source_total': pickList(
      'registrations_by_source_total',
      'registrations_by_source',
    ),
    'logins_by_client_week': pickList(
      'logins_by_client_week',
      'logins_week_by_platform',
    ) ??
        pickList('logins_by_client_week', 'logins_week_by_client'),
    'registrations_by_client_week': pickList(
      'registrations_by_client_week',
      'registers_week_by_client',
    ),
    'app_versions_week': pickList(
      'app_versions_week',
      'mobile_app_top_versions',
    ),
    'mobile_app_by_platform':
        raw['mobile_app_by_platform'] ?? clients['mobile_app_by_platform'],
    'logins_week_by_client':
        raw['logins_week_by_client'] ?? clients['logins_week_by_client'],
  };
}

/// Человекочитаемые подписи для bar-графиков (API: mobile, web, неизвестно…).
String dashboardBarLabelRu(String raw) {
  final key = raw.trim().toLowerCase();
  return switch (key) {
    'неизвестно' || 'unknown' || '' => 'Не указано',
    'mobile' || 'app' || 'приложение' || 'мобильное приложение' => 'Моб. приложение',
    'web' || 'site' || 'сайт' => 'Сайт',
    'invite' || 'invitation' || 'приглашение' => 'Приглашение',
    'ios' => 'iOS',
    'android' => 'Android',
    'windows' => 'windows',
    _ => _capitalizeVersionLabel(raw),
  };
}

String _capitalizeVersionLabel(String raw) {
  if (RegExp(r'^\d+\.\d+').hasMatch(raw)) return raw;
  if (raw.isEmpty) return raw;
  return raw[0].toUpperCase() + raw.substring(1);
}
