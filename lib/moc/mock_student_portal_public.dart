/// Снимок `GET /student-portal` по логам реального API.
Map<String, dynamic> mockStudentPortalPublicSnapshot() => {
      'schedule_semesters': [
        {
          'id': 1,
          'title': 'II семестр 2026',
          'sort_order': 1,
          'entries': [
            {
              'id': 1,
              'label': 'Информационные системы и программирование',
              'file_url':
                  '/uploads/student_portal/633c185ec9764650ab8082fb5fda46f9_Анкета_4_МОДУЛЬ.pdf',
              'original_filename': 'Анкета 4 МОДУЛЬ.pdf',
              'file_size': 150998,
            },
          ],
        },
      ],
      'overview': {
        'body_html': '<p></p>',
        'hub_links': [
          {
            'label': 'Расписание занятий',
            'href': '/svedeniya/studentam/raspisanie-zanyatiy',
            'external': false,
          },
          {
            'label': 'Расписание сессий',
            'href': '/svedeniya/studentam/raspisanie-sessiy',
            'external': false,
          },
          {
            'label': 'Электронные ресурсы',
            'href': '/svedeniya/studentam/elektronnye-resursy',
            'external': false,
          },
          {
            'label': 'ВПР',
            'href': '/svedeniya/studentam/vpr',
            'external': false,
          },
          {'label': 'СНО', 'href': 'https://sno.dgu.ru/', 'external': true},
          {
            'label': 'Образовательные программы',
            'href': 'https://dgu.ru/sveden/opop/',
            'external': true,
          },
        ],
      },
      'vpr': {
        'page_title': 'ВПР',
        'body_html': '<p></p>',
        'file_url': null,
        'original_filename': null,
        'file_size': null,
      },
      'eresources': {
        'body_html': r'''
<h2>Регистрация на платформе ЮРАЙТ</h2>
<ul>
  <li><a href="https://urait.ru/" rel="noopener noreferrer" target="_blank">Юрайт. Зарегистрироваться и авторизоваться</a></li>
  <li><a href="https://urait.ru/" rel="noopener noreferrer" target="_blank">Юрайт. Общий плакат о платформе для СПО</a></li>
  <li><a href="https://urait.ru/" rel="noopener noreferrer" target="_blank">Юрайт. Библиотека. Приложение студентам</a></li>
  <li><a href="https://urait.ru/" rel="noopener noreferrer" target="_blank">Юрайт. Преподавателям</a></li>
</ul>
<h2>ЭБС в образовательной деятельности ДГУ</h2>
<h3>Официальная информация про ЭБС</h3>
<p>Электронная библиотечная система «Юрайт» <a href="https://biblio-online.ru/" rel="noopener noreferrer" target="_blank">biblio-online.ru</a> — это виртуальный читальный зал учебников и учебных пособий от авторов из ведущих вузов России по экономическим, юридическим, гуманитарным, инженерно-техническим и естественно-научным направлениям и специальностям. На сегодняшний день портфель издательства включает в себя более 3500 наименований.</p>
<p><em>(Текст укорочен по сравнению с полным ответом API; в моке — типичный фрагмент из лога.)</em></p>
''',
      },
    };
