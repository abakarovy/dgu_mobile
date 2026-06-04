/// Подразделы «Студентам» — паритет с `eduDisclosureNav.ts` / STUDENTAM_SVEDENIYA_BACKEND.md.
abstract final class StudentPortalConstants {
  StudentPortalConstants._();

  static const overviewSectionId = 'razdel';
  static const scheduleSectionId = 'raspisanie-zanyatiy';
  static const sessionsSectionId = 'raspisanie-sessiy';
  static const eresourcesSectionId = 'elektronnye-resursy';
  static const vprSectionId = 'vpr';

  /// Устаревший путь на сайте → редирект на `raspisanie-sessiy`.
  static const deprecatedHubPathSegment = 'sessii-po-otdeleniyam';

  static const sessionsDepartmentTitleDefault =
      'Расписание сессии и пересдачи по отделениям';
  static const giaDepartmentTitleDefault =
      'Государственная итоговая аттестация (ГИА)';

  static const sectionTabs = <({String id, String label})>[
    (id: overviewSectionId, label: 'Общая информация'),
    (id: scheduleSectionId, label: 'Расписание'),
    (id: sessionsSectionId, label: 'Сессии'),
    (id: eresourcesSectionId, label: 'Электронные ресурсы'),
    (id: vprSectionId, label: 'ВПР'),
  ];
}
