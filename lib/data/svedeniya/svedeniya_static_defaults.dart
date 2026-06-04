/// Статика сведений — паритет с frontend defaults (SVEDENIYA_OO_MOBILE_AUDIT.md, часть 5).
abstract final class SvedeniyaStaticDefaults {
  static const fullOrgName =
      'Федеральное государственное бюджетное образовательное учреждение высшего образования '
      '«Дагестанский государственный университет» (колледж)';

  static const shortOrgName = 'Колледж ДГУ';

  static const address =
      '367000, Республика Дагестан, г. Махачкала, ул. Дзержинского, 21';

  static const phoneDisplay = '+7 (872) 267-00-00';

  static const phoneHref = 'tel:+78722670000';

  static const email = 'collegedsu@mail.ru';

  /// STATIC_FOUNDER — `osnovnyeSvedeniyaStatic.ts`
  static const founderHtml = '''
<p>Учредителем колледжа является Министерство науки и высшего образования Российской Федерации.</p>
<p>Федеральное государственное бюджетное образовательное учреждение высшего образования «Дагестанский государственный университет».</p>
''';

  /// STATIC_LOCATION_CONTACT
  static const locationHtml = '''
<p><strong>$fullOrgName</strong></p>
<p>$address</p>
<p>Тел.: <a href="$phoneHref">$phoneDisplay</a></p>
<p>E-mail: <a href="mailto:$email">$email</a></p>
''';

  /// `OKOLLEGE_SVEDENIYA_DEFAULTS` — skeleton + hero (main_html без oKollegeHtmlObshaya.ts).
  static Map<String, dynamic> get okollegeDefaults => {
        'obshaya_informatsiya': {
          'eyebrow': 'О колледже',
          'eyebrow_intro':
              'Структура, задачи, направления подготовки и специальности — ключевые сведения для абитуриентов и партнёров.',
          'main_html': '''
<p>Колледж ДГУ готовит специалистов среднего профессионального образования по востребованным направлениям.</p>
<p>Современный кампус, цифровые сервисы для учёбы и прозрачный образовательный процесс для студентов и родителей.</p>
''',
        },
        'data_sozdaniya': {
          'eyebrow': 'Основание деятельности',
          'eyebrow_intro':
              'Колледж создан приказом ректора; ниже — скан приказа и документы по лицензированию и аккредитации.',
          'highlight_title': '27 мая 2013',
          'highlight_body_html':
              '<p>Юридический колледж при юридическом факультете ДГУ создан на основании приказа ректора ФГБОУ ВО «Дагестанский государственный университет» № 331а–1 от 27.05.2013 г.</p>',
          'documents': dataSozdaniyaDocuments,
        },
        'uchreditel_html': '',
        'mestonakhozhdenie_html': locationHtml,
        'rezhim_grafik_blocks': workScheduleBlocks,
        'sotrudnichestvo': {
          'eyebrow': 'Работодатели и партнёры',
          'main_html': '''
<p>Колледж сотрудничает с органами власти, работодателями и образовательными партнёрами региона.</p>
''',
          'bottom_documents': sotrudnichestvoDocuments,
        },
        'vypuskniki_html': '',
        'kontaktnaya_informatsiya': {
          'card_eyebrow': 'Официальное наименование',
          'full_org_html': '<p>$fullOrgName</p>',
          'short_prefix': 'Сокращённое наименование:',
          'short_org_name': shortOrgName,
          'postal_lines': [address],
          'phone_display': phoneDisplay,
          'phone_href': phoneHref,
          'email': email,
        },
      };

  static const dataSozdaniyaDocuments = [
    {
      'label': 'Приказ (скан изображения)',
      'href': 'https://law.dgu.ru/college/Content/files/Scan-160213-0002.jpg',
    },
    {
      'label': 'Свидетельство о государственной аккредитации',
      'href': 'https://ndoc.dgu.ru/PDFF/Gak_ot_24_04_2019.pdf',
    },
    {
      'label': 'Выписка из реестра лицензий',
      'href': 'https://law.dgu.ru/college/Content/files/Реестровая%20выписка.pdf',
    },
    {
      'label': 'Приложение к лицензии № 1.1',
      'href': 'https://law.dgu.ru/college/Content/files/лицензия%20на%20сайт%20колледжа.pdf',
    },
    {
      'label': 'Приложение к лицензии № 1.2',
      'href': 'https://law.dgu.ru/college/Content/files/лицкезия%20пса.pdf',
    },
    {
      'label': 'Приложение № 7 к свидетельству о гос. аккредитации',
      'href': 'https://law.dgu.ru/college/Content/files/аккред.pdf',
    },
  ];

  static const sotrudnichestvoDocuments = [
    {
      'label': 'Договор о творческом сотрудничестве (PDF)',
      'href': 'https://law.dgu.ru/college/Content/files/договор%20о%20творческом%20сотр(1).pdf',
    },
    {
      'label': 'Перечень баз практик (PDF)',
      'href': 'https://law.dgu.ru/college/Content/files/перечень%20баз%20практик(1).pdf',
    },
  ];

  static const workScheduleBlocks = [
    {
      'title': 'Режим работы колледжа',
      'lines': ['Пн–Пт: 9:00–18:00', 'Сб–Вс: выходной'],
    },
    {
      'title': 'Приёмная директора',
      'lines': ['По предварительной записи', 'Тел.: $phoneDisplay'],
    },
  ];

  static const stipendiiSocialBenefitsDefault = {
    'label': 'Социальные льготы и поддержка',
    'href': 'https://dgu.ru/sveden/grants/',
  };

  /// TEACHER_MENU_LINKS — external_links_svedeniya.json
  static const teacherLinks = [
    {'label': 'Рейтинговая система', 'href': 'https://rate.dgu.ru'},
    {'label': 'Наука и инновации', 'href': 'https://science.dgu.ru'},
    {'label': 'Образование и инновации', 'href': 'https://ed.dgu.ru'},
    {'label': 'Электронная информационно-образовательная среда (ЭИОС)', 'href': 'https://bitrix.dgu.ru/eios/'},
    {'label': 'Научная библиотека', 'href': 'https://elib.dgu.ru'},
  ];

  static const vypusknikiPlaceholder = 'Раздел в разработке.';

  static const sportkompleksPlaceholder = 'Раздел в подготовке.';
}
