/// Дерево меню сведений — паритет с `eduDisclosureNav.ts` (SVEDENIYA_OO_FULL.md §4).
abstract final class EduDisclosureNav {
  static const roots = <SvedeniyaRoot>[
    SvedeniyaRoot(
      id: 'osnovnye-svedeniya',
      title: 'О колледже',
      children: [
        SvedeniyaChild(id: 'obshaya-informatsiya', title: 'Общая информация'),
        SvedeniyaChild(id: 'data-sozdaniya', title: 'Дата создания'),
        SvedeniyaChild(id: 'uchreditel', title: 'Учредитель'),
        SvedeniyaChild(id: 'mestonakhozhdenie', title: 'Местонахождение'),
        SvedeniyaChild(id: 'rezhim-grafik', title: 'Режим и график работы'),
        SvedeniyaChild(id: 'sotrudnichestvo', title: 'Сотрудничество'),
        SvedeniyaChild(id: 'vypuskniki', title: 'Выпускники'),
        SvedeniyaChild(id: 'kontaktnaya-informatsiya', title: 'Контактная информация'),
      ],
    ),
    SvedeniyaRoot(
      id: 'struktura',
      title: 'Структура колледжа',
      children: [
        SvedeniyaChild(id: 'struktura-kolledzha', title: 'Структура колледжа'),
        SvedeniyaChild(id: 'kadrovy-sostav', title: 'Кадровый состав'),
        SvedeniyaChild(id: 'otchyot-o-samoobsledovanii', title: 'Отчёт о самообследовании'),
        SvedeniyaChild(
          id: 'psikhologo-pedagogicheskaya-sluzhba',
          title: 'Психолого-педагогическая служба',
        ),
        SvedeniyaChild(
          id: 'besplatnaya-meditsinskaya-pomoshch',
          title: 'Бесплатная медицинская помощь',
        ),
        SvedeniyaChild(id: 'kafedry', title: 'Кафедры'),
        SvedeniyaChild(id: 'sostav-soveta-kolledzha', title: 'Состав совета колледжа'),
        SvedeniyaChild(
          id: 'sostav-uchebno-metodicheskogo-soveta-kolledzha',
          title: 'Состав учебно-методического совета',
        ),
      ],
    ),
    SvedeniyaRoot(
      id: 'dokumenty',
      title: 'Нормативные документы',
      children: [
        SvedeniyaChild(id: 'katalog', title: 'Нормативные документы (каталог)'),
        SvedeniyaChild(id: 'arhiv', title: 'Файловый архив'),
      ],
    ),
    SvedeniyaRoot(
      id: 'obrazovanie',
      title: 'Образование',
      children: [
        SvedeniyaChild(id: 'sveden-dgu', title: 'Образование'),
      ],
    ),
    SvedeniyaRoot(
      id: 'mto',
      title: 'Материально-техническое обеспечение',
      children: [
        SvedeniyaChild(id: 'finansovoe-obespechenie', title: 'Финансовое обеспечение'),
        SvedeniyaChild(id: 'uchebnye-kabinety', title: 'Учебные кабинеты'),
        SvedeniyaChild(id: 'obekty-prakticheskih-zanyatiy', title: 'Объекты практических занятий'),
        SvedeniyaChild(id: 'biblioteka', title: 'Библиотека'),
        SvedeniyaChild(id: 'sportkompleks', title: 'Спорткомплекс'),
      ],
    ),
    SvedeniyaRoot(
      id: 'stipendii',
      title: 'Стипендии и материальная поддержка',
      children: [
        SvedeniyaChild(id: 'podderzhka', title: 'Стипендии, общежитие, трудоустройство'),
      ],
    ),
    SvedeniyaRoot(
      id: 'biblioteka-i-sport',
      title: 'Библиотека и спорткомплекс',
      children: [
        SvedeniyaChild(id: 'biblioteka', title: 'Библиотека'),
        SvedeniyaChild(id: 'sportkompleks', title: 'Спорткомплекс'),
      ],
    ),
    SvedeniyaRoot(
      id: 'vospitatelnaya-deyatelnost',
      title: 'Воспитательная деятельность',
      children: [
        SvedeniyaChild(
          id: 'ekstremizm-terrorizm',
          title: 'Противодействие экстремизму и терроризму',
        ),
        SvedeniyaChild(id: 'korruptsiya', title: 'Противодействие коррупции'),
        SvedeniyaChild(id: 'kodeks-chesti', title: 'Кодекс чести'),
        SvedeniyaChild(id: 'narkotiki', title: 'Наркотические средства'),
        SvedeniyaChild(id: 'samoupravlenie', title: 'Студенческое самоуправление'),
      ],
    ),
    SvedeniyaRoot(
      id: 'nauchnaya-zhizn',
      title: 'Наука',
      children: [
        SvedeniyaChild(id: 'chempionat-professionaly', title: 'Чемпионат «Профессионалы»'),
        SvedeniyaChild(id: 'nauchnye-kruzhki', title: 'Научные кружки'),
        SvedeniyaChild(id: 'konkursy-i-olimpiady', title: 'Конкурсы и олимпиады'),
      ],
    ),
    SvedeniyaRoot(
      id: 'pedagogam-resursy',
      title: 'Преподавателям',
      children: [
        SvedeniyaChild(id: 'vneshnie-ssylki', title: 'Ресурсы университета'),
      ],
    ),
    SvedeniyaRoot(
      id: 'studentam',
      title: 'Студентам',
      children: [
        SvedeniyaChild(id: 'razdel', title: 'Общая информация'),
        SvedeniyaChild(id: 'raspisanie-zanyatiy', title: 'Расписание занятий'),
        SvedeniyaChild(id: 'raspisanie-sessiy', title: 'Расписание сессий'),
        SvedeniyaChild(id: 'elektronnye-resursy', title: 'Электронные ресурсы'),
        SvedeniyaChild(id: 'vpr', title: 'ВПР'),
        SvedeniyaChild(id: 'sno', title: 'СНО'),
      ],
    ),
  ];

  static SvedeniyaRoot? rootById(String id) {
    for (final r in roots) {
      if (r.id == id) return r;
    }
    return null;
  }

  static SvedeniyaChild? childById(String rootId, String childId) {
    final root = rootById(rootId);
    if (root == null) return null;
    for (final c in root.children) {
      if (c.id == childId) return c;
    }
    return null;
  }

  static String pathKey(String rootId, String childId) => '$rootId/$childId';
}

class SvedeniyaRoot {
  const SvedeniyaRoot({required this.id, required this.title, required this.children});

  final String id;
  final String title;
  final List<SvedeniyaChild> children;
}

class SvedeniyaChild {
  const SvedeniyaChild({required this.id, required this.title});

  final String id;
  final String title;
}

/// URL segment → `category` в `GET /api/upbringing` (§12).
abstract final class VospitanieNav {
  static const categoryByChild = <String, String>{
    'ekstremizm-terrorizm': 'extremism',
    'korruptsiya': 'corruption',
    'kodeks-chesti': 'honor_code',
    'narkotiki': 'narcotics',
    'samoupravlenie': 'student_self_gov',
  };
}

/// Поле `mto` для подраздела МТО (§9).
abstract final class MtoNav {
  static const fieldByChild = <String, String>{
    'finansovoe-obespechenie': 'financial_support',
    'uchebnye-kabinety': 'cabinets',
    'obekty-prakticheskih-zanyatiy': 'practice_facilities',
    'biblioteka': 'libraries',
    'sportkompleks': 'sport',
  };
}
