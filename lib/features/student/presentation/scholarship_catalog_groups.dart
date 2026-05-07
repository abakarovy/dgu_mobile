// Группировка критериев каталога стипендии по `section_ref` (1.1, 1.2, …).

typedef ScholarshipCatalogGroup = ({
  String ref,
  String title,
  List<Map<String, dynamic>> items,
});

List<ScholarshipCatalogGroup> groupScholarshipCatalog(List<Map<String, dynamic>> catalog) {
  final order = <String>[];
  final map = <String, List<Map<String, dynamic>>>{};
  final titles = <String, String>{};

  for (final c in catalog) {
    final ref = '${c['section_ref'] ?? ''}'.trim();
    final key = ref.isEmpty ? '_' : ref;
    if (!map.containsKey(key)) {
      order.add(key);
      map[key] = [];
      titles[key] = '${c['section_title'] ?? ''}'.trim();
    }
    map[key]!.add(c);
  }

  return [
    for (final key in order)
      (
        ref: key == '_' ? '' : key,
        title: titles[key] ?? '',
        items: map[key]!,
      ),
  ];
}
