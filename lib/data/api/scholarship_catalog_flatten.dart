/// Ответ `GET /scholarship-rating/catalog`: либо плоский список критериев, либо объект с `categories` → `sections` → `criteria`.
List<Map<String, dynamic>> flattenScholarshipRatingCatalog(dynamic data) {
  if (data == null) return [];
  if (data is List) {
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (data is! Map) return [];
  final root = Map<String, dynamic>.from(data);
  final categories = root['categories'];
  if (categories is! List) return [];

  var seq = 0;
  final out = <Map<String, dynamic>>[];
  for (final cat in categories) {
    if (cat is! Map) continue;
    final catMap = Map<String, dynamic>.from(cat);
    final catId = '${catMap['id'] ?? catMap['category_id'] ?? ''}'.trim();
    final catShort = '${catMap['short'] ?? catMap['label'] ?? ''}'.trim();
    final sections = catMap['sections'];
    if (sections is! List) continue;
    for (final sec in sections) {
      if (sec is! Map) continue;
      final secMap = Map<String, dynamic>.from(sec);
      final sectionRef = '${secMap['id'] ?? ''}'.trim();
      final secTitle = '${secMap['title'] ?? ''}'.trim();
      final criteria = secMap['criteria'];
      if (criteria is! List) continue;
      for (final crit in criteria) {
        if (crit is! Map) continue;
        final c = Map<String, dynamic>.from(crit);
        seq++;
        final rawId = c['id'];
        final ref = '$rawId';
        out.add({
          'id': seq,
          'category_id': catId,
          'category_label': catShort,
          'section_ref': sectionRef,
          'section_title': secTitle,
          'criterion_ref': ref,
          'title': '${c['label'] ?? c['title'] ?? 'Критерий'}',
          'description': [if (catShort.isNotEmpty) catShort, if (secTitle.isNotEmpty) secTitle]
              .join('. '),
          'max_points': c['points'] ?? c['max_points'],
          'allow_upload': c['allow_upload'] == true,
          'divide_by_coauthors': c['divide_by_coauthors'] == true,
          'options': c['options'] is List ? List<dynamic>.from(c['options'] as List) : const <dynamic>[],
        });
      }
    }
  }
  return out;
}
