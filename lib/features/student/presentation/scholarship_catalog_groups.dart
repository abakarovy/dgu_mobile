// Группировка критериев каталога стипендии по категории и `section_ref` (см. category_id в каталоге ДГУ).

typedef ScholarshipCatalogGroup = ({
  String categoryId,
  String categoryLabel,
  String ref,
  String title,
  List<Map<String, dynamic>> items,
});

/// Блок каталога: «1. Учёба» и список подразделов 1.1, 1.2, …
typedef ScholarshipCategoryBlock = ({
  int ordinal,
  String categoryId,
  String categoryLabel,
  List<ScholarshipCatalogGroup> sections,
});

List<ScholarshipCatalogGroup> groupScholarshipCatalog(List<Map<String, dynamic>> catalog) {
  final order = <String>[];
  final map = <String, List<Map<String, dynamic>>>{};
  final meta = <String, ({String categoryId, String categoryLabel, String sectionRef, String sectionTitle})>{};

  for (final c in catalog) {
    final sectionRef = '${c['section_ref'] ?? ''}'.trim();
    final categoryId = '${c['category_id'] ?? ''}'.trim();
    final key = categoryId.isNotEmpty ? '$categoryId::$sectionRef' : (sectionRef.isEmpty ? '_' : sectionRef);
    if (!map.containsKey(key)) {
      order.add(key);
      map[key] = [];
      meta[key] = (
        categoryId: categoryId,
        categoryLabel: '${c['category_label'] ?? ''}'.trim(),
        sectionRef: sectionRef,
        sectionTitle: '${c['section_title'] ?? ''}'.trim(),
      );
    }
    map[key]!.add(c);
  }

  return [
    for (final key in order)
      (
        categoryId: meta[key]!.categoryId,
        categoryLabel: meta[key]!.categoryLabel,
        ref: meta[key]!.sectionRef.isEmpty && key == '_' ? '' : meta[key]!.sectionRef,
        title: meta[key]!.sectionTitle,
        items: map[key]!,
      ),
  ];
}

/// Склеивает подряд идущие группы одной категории в блоки вида «1. Учёба» → [1.1, 1.2, …].
List<ScholarshipCategoryBlock> scholarshipCatalogByCategory(List<ScholarshipCatalogGroup> grouped) {
  final out = <ScholarshipCategoryBlock>[];
  for (final g in grouped) {
    final id = g.categoryId.isNotEmpty ? g.categoryId : '_';
    final label = g.categoryLabel.isNotEmpty ? g.categoryLabel : 'Критерии';
    if (out.isEmpty || out.last.categoryId != id) {
      out.add((ordinal: out.length + 1, categoryId: id, categoryLabel: label, sections: [g]));
    } else {
      final last = out.removeLast();
      out.add((
        ordinal: last.ordinal,
        categoryId: last.categoryId,
        categoryLabel: last.categoryLabel,
        sections: [...last.sections, g],
      ));
    }
  }
  return out;
}
