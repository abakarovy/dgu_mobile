import 'student_portal_constants.dart';

/// Фильтрация `overview.hub_links` как на сайте.
abstract final class StudentPortalHub {
  StudentPortalHub._();

  static List<Map<String, dynamic>> filtered(dynamic hub) {
    if (hub is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final raw in hub) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final href = '${m['href'] ?? ''}'.trim().toLowerCase();
      if (href.contains(StudentPortalConstants.deprecatedHubPathSegment)) continue;
      final label = '${m['label'] ?? ''}'.trim();
      if (label.isEmpty || href.isEmpty) continue;
      out.add(m);
    }
    return out;
  }
}
