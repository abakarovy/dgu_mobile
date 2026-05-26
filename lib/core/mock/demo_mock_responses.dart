import 'package:dio/dio.dart';

import 'demo_api_interceptor.dart';
import 'demo_persona.dart';
import 'demo_session.dart';

/// Моковые тела ответов для [DemoSession] (по структуре college.dgu.ru).
abstract final class DemoMockResponses {
  static DemoMockPayload? tryResolve(RequestOptions options) {
    final path = _normPath(options.path);
    final method = options.method.toUpperCase();

    if (method == 'GET') {
      return _get(path, options);
    }
    if (method == 'POST' || method == 'PATCH' || method == 'PUT' || method == 'DELETE') {
      return _mutate(path, method, options);
    }
    return null;
  }

  static String _normPath(String raw) {
    var p = raw.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) {
      final uri = Uri.tryParse(p);
      if (uri != null) p = uri.path;
    }
    if (!p.startsWith('/')) p = '/$p';
    if (p.length > 1 && p.endsWith('/')) p = p.substring(0, p.length - 1);
    return p;
  }

  static DemoMockPayload? _get(String path, RequestOptions options) {
    if (path == '/auth/me') {
      return DemoMockPayload(statusCode: 200, data: DemoSession.demoUser.toJson());
    }
    if (path == '/groups/my') {
      return const DemoMockPayload(statusCode: 200, data: <dynamic>[]);
    }
    if (path == '/1c/my-profile') {
      return DemoMockPayload(statusCode: 200, data: _myProfile());
    }
    if (path == '/1c/schedule') {
      final forDate = options.queryParameters['for_date']?.toString();
      final now = DateTime.now();
      final ymd = forDate?.trim().isNotEmpty == true
          ? forDate!.trim()
          : _ymd(DateTime(now.year, now.month, now.day));
      return DemoMockPayload(statusCode: 200, data: _scheduleEnvelope(ymd));
    }
    if (path == '/1c/sync-grades') {
      return DemoMockPayload(statusCode: 200, data: _syncGrades());
    }
    if (path == '/1c/final-grades') {
      return DemoMockPayload(statusCode: 200, data: {'grades': []});
    }
    if (path == '/1c/curriculum') {
      return DemoMockPayload(statusCode: 200, data: _curriculum());
    }
    if (path == '/1c/absences') {
      return DemoMockPayload(statusCode: 200, data: _absences());
    }
    if (path == '/1c/student-photo') {
      return DemoMockPayload(statusCode: 404, data: {'detail': 'Фото не найдено'});
    }
    if (path == '/journal/grades/my') {
      return DemoMockPayload(statusCode: 200, data: []);
    }
    if (path == '/news' || path.startsWith('/news/')) {
      if (path.startsWith('/news/') && path != '/news') {
        final id = int.tryParse(path.split('/').last) ?? 1;
        return DemoMockPayload(statusCode: 200, data: _newsItem(id));
      }
      return DemoMockPayload(statusCode: 200, data: _newsList());
    }
    if (path == '/mobile/events') {
      return DemoMockPayload(statusCode: 200, data: _eventsList());
    }
    if (path == '/mobile/help') {
      return DemoMockPayload(statusCode: 200, data: _help());
    }
    if (path == '/mobile/notification-preferences') {
      return DemoMockPayload(statusCode: 200, data: _notificationPrefs());
    }
    if (path == '/mobile/student-ticket') {
      return DemoMockPayload(statusCode: 200, data: _studentTicketEnvelope());
    }
    if (path == '/mobile/assignments/my') {
      return DemoMockPayload(statusCode: 200, data: _assignments());
    }
    if (path == '/students/me/parent-status') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'linked': false,
          'parent_has_account': false,
          'parent_email_masked': null,
          'link_status': null,
        },
      );
    }
    if (path == '/lms') {
      return DemoMockPayload(statusCode: 200, data: _lmsList());
    }
    if (path.startsWith('/lms/')) {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'id': 1,
          'title': 'ЭБС «Юрайт»',
          'url': 'https://urait.ru',
          'login_hint': 'Логин выдаётся в библиотеке колледжа',
        },
      );
    }
    if (path == '/portfolio/my') {
      return DemoMockPayload(statusCode: 200, data: {'items': _portfolioItems()});
    }
    if (path == '/portfolio/my-complete') {
      return DemoMockPayload(statusCode: 200, data: {'complete': false, 'missing': []});
    }
    if (path == '/portfolio/rating') {
      return DemoMockPayload(
        statusCode: 200,
        data: {'position': 8, 'total_students': 32, 'score': 31.0},
      );
    }
    if (path == '/portfolio/share') {
      return DemoMockPayload(statusCode: 200, data: {'enabled': false});
    }
    if (path == '/students/department-announcements/my') {
      return DemoMockPayload(statusCode: 200, data: _deptAnnouncements());
    }
    if (path == '/scholarship-rating/catalog') {
      return DemoMockPayload(statusCode: 200, data: _scholarshipCatalog());
    }
    if (path == '/scholarship-rating/my/summary') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'academic_year': '2025-2026',
          'semester': 'spring',
          'total_score': 22,
          'entries': [],
        },
      );
    }
    if (path == '/student-portal') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'title': 'Студентам',
          'links': [
            {'title': 'Стипендия', 'href': '/svedeniya/students/scholarships/'},
            {'title': 'Общежитие', 'href': '/svedeniya/students/dormitory/'},
          ],
        },
      );
    }
    if (path == '/health') {
      return DemoMockPayload(statusCode: 200, data: {'status': 'ok', 'demo': true});
    }
    return DemoMockPayload(statusCode: 200, data: <String, dynamic>{});
  }

  static DemoMockPayload? _mutate(String path, String method, RequestOptions options) {
    if (path == '/auth/login') {
      return DemoMockPayload(statusCode: 200, data: DemoSession.demoUser.toJson());
    }
    if (path == '/students/me/wifi-password-request') {
      return DemoMockPayload(
        statusCode: 200,
        data: {'message': 'Заявка принята. Пароль Wi‑Fi будет настроен в течение 1–2 рабочих дней.'},
      );
    }
    if (path == '/push/device') {
      return DemoMockPayload(statusCode: method == 'DELETE' ? 204 : 201, data: {});
    }
    if (path == '/mobile/notification-preferences' && method == 'PATCH') {
      final body = options.data;
      if (body is Map) {
        return DemoMockPayload(statusCode: 200, data: Map<String, dynamic>.from(body));
      }
      return DemoMockPayload(statusCode: 200, data: _notificationPrefs());
    }
    if (path.startsWith('/portfolio/') || path.startsWith('/scholarship-rating/')) {
      return DemoMockPayload(statusCode: 200, data: {'ok': true});
    }
    return DemoMockPayload(statusCode: 200, data: {'ok': true});
  }

  static Map<String, dynamic> _myProfile() => {
        'is_cached': true,
        'student_id': DemoPersona.studentBookNumber,
        'last_name': DemoPersona.lastName,
        'first_name': DemoPersona.firstName,
        'middle_name': DemoPersona.patronymic,
        'birthday': DemoPersona.birthday,
        'full_name': DemoPersona.fullName,
        'student_book_number': DemoPersona.studentBookNumber,
        'group': DemoPersona.studyGroup,
        'department': DemoPersona.department,
        'direction': DemoPersona.direction,
        'course': DemoPersona.course,
        'curator': DemoPersona.curator,
        'funding_type': DemoPersona.fundingType,
        'budget_type': 'Федеральный',
        'education_form': DemoPersona.studyForm,
        'study_form': DemoPersona.studyForm,
        'admission_year': DemoPersona.admissionYear,
        'status': DemoPersona.status,
        'social_role': '',
        'grades': _syncGrades()['grades'],
      };

  static Map<String, dynamic> _studentTicketEnvelope() => {
        'full_name': DemoPersona.fullName,
        'student_book_number': DemoPersona.studentBookNumber,
        'ticket_valid_until': null,
        'ticket_issued_at': null,
        'study_form': DemoPersona.studyForm,
        'course': DemoPersona.course,
        'birth_date': DemoPersona.birthday,
        'department': DemoPersona.department,
        'study_group': DemoPersona.studyGroup,
        'admission_year': DemoPersona.admissionYear,
        'status': DemoPersona.status,
      };

  static Map<String, dynamic> _syncGrades() => {
        'grades': [
          {
            'semester': '1 сем 2025-2026',
            'records': [
              {
                'subject': 'Веб-программирование',
                'grade': '4',
                'type': 'Контрольная работа',
                'date': '2026-04-15',
                'teacher_name': 'Хангишиева Аида Хабибуллаевна',
              },
              {
                'subject': 'Системное программирование',
                'grade': '5',
                'type': 'Практическое занятие',
                'date': '2026-04-22',
                'teacher_name': 'Атаев Ахмед Арсенович',
              },
              {
                'subject': 'Поддержка и тестирование программных модулей',
                'grade': '4',
                'type': 'Лабораторная',
                'date': '2026-05-06',
                'teacher_name': 'Багирова София Динмагомедовна',
              },
              {
                'subject': 'Разработка мобильных приложений',
                'grade': '5',
                'type': 'Проект',
                'date': '2026-05-12',
                'teacher_name': 'Хангишиева Аида Хабибуллаевна',
              },
              {
                'subject': 'Технология разработки программного обеспечения',
                'grade': '3',
                'type': 'Тест',
                'date': '2026-05-18',
                'teacher_name': 'Атаев Ахмед Арсенович',
              },
            ],
          },
          {
            'semester': '2 сем 2024-2025',
            'records': [
              {
                'subject': 'Инструментальные средства разработки ПО',
                'grade': '4',
                'type': 'Экзамен',
                'date': '2025-06-10',
              },
              {
                'subject': 'Безопасность жизнедеятельности',
                'grade': '5',
                'type': 'Зачёт',
                'date': '2025-06-18',
              },
            ],
          },
        ],
      };

  static Map<String, dynamic> _curriculum() => {
        'curriculum': [
          {
            'subject': 'Разработка мобильных приложений',
            'semester': '6 семестр',
            'control_form': 'Экзамен',
            'hours': {
              'total': 144,
              'theory_lectures': 36,
              'practical': 72,
              'lab': 36,
            },
          },
          {
            'subject': 'Веб-программирование',
            'semester': '6 семестр',
            'control_form': 'Дифференцированный зачёт',
            'hours': {'total': 108, 'theory_lectures': 36, 'practical': 72, 'lab': 0},
          },
          {
            'subject': 'Системное программирование',
            'semester': '5 семестр',
            'control_form': 'Экзамен',
            'hours': {'total': 126, 'theory_lectures': 36, 'practical': 54, 'lab': 36},
          },
          {
            'subject': 'Поддержка и тестирование программных модулей',
            'semester': '5 семестр',
            'control_form': 'Экзамен',
            'hours': {'total': 108, 'theory_lectures': 18, 'practical': 54, 'lab': 36},
          },
        ],
        'is_cached': true,
      };

  static Map<String, dynamic> _absences() => {
        'student_id': DemoPersona.studentBookNumber,
        'status': 'success',
        'semesters': [
          {
            'semester': '1 сем 2025-2026',
            'period': {'start': '01.09.2025', 'end': '31.01.2026'},
            'data': {
              'total_absences': 6,
              'excused_absences': 2,
              'unexcused_absences': 4,
            },
          },
          {
            'semester': '2 сем 2024-2025',
            'period': {'start': '01.02.2025', 'end': '30.06.2025'},
            'data': {
              'total_absences': 4,
              'excused_absences': 1,
              'unexcused_absences': 3,
            },
          },
        ],
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

  /// Обёртка как у бэка: `schedule`, `schedule_scope`, `schedule_for_date`.
  static Map<String, dynamic> _scheduleEnvelope(String ymd) => {
        'schedule': _scheduleForDate(ymd),
        'week': null,
        'is_cached': true,
        'schedule_scope': 'today',
        'schedule_for_date': ymd,
      };

  /// Пары на каждый будний день (чтобы «сегодня» и неделя не были пустыми).
  static List<Map<String, dynamic>> _scheduleForDate(String ymd) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(ymd.trim());
    if (m == null) return [];
    final y = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final d = int.tryParse(m.group(3)!);
    if (y == null || mo == null || d == null) return [];

    final day = DateTime(y, mo, d);
    final wd = day.weekday;
    if (wd == DateTime.saturday || wd == DateTime.sunday) {
      return [];
    }

    const dayNames = [
      '',
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    final dayLabel = dayNames[wd];

    // Шаблоны по дню недели (как в 1С: разные дисциплины в разные дни).
    final templates = switch (wd) {
      DateTime.monday => [
        ('08:30 - 10:05', 1, 'Веб-программирование', '214', 'Хангишиева Аида Хабибуллаевна'),
        ('10:15 - 11:50', 2, 'Системное программирование', '105', 'Атаев Ахмед Арсенович'),
        ('12:10 - 13:45', 3, 'Поддержка и тестирование программных модулей', '202', 'Багирова София Динмагомедовна'),
      ],
      DateTime.tuesday => [
        ('08:30 - 10:05', 1, 'Технология разработки программного обеспечения', '202', 'Атаев Ахмед Арсенович'),
        ('10:15 - 11:50', 2, 'Разработка мобильных приложений', '207', 'Хангишиева Аида Хабибуллаевна'),
        ('12:10 - 13:45', 3, 'Инструментальные средства разработки программного обеспечения', '202', 'Багирова София Динмагомедовна'),
      ],
      DateTime.wednesday => [
        ('08:30 - 10:05', 1, 'Разработка мобильных приложений', '214', 'Хангишиева Аида Хабибуллаевна'),
        ('10:15 - 11:50', 2, 'Технология разработки программного обеспечения', '202', 'Атаев Ахмед Арсенович'),
        ('12:10 - 13:45', 3, 'Разработка мобильных приложений', '207', 'Хангишиева Аида Хабибуллаевна'),
        ('14:00 - 15:35', 4, 'Инструментальные средства разработки программного обеспечения', '202', 'Багирова София Динмагомедовна'),
      ],
      DateTime.thursday => [
        ('08:30 - 10:05', 1, 'Веб-программирование', '214', 'Хангишиева Аида Хабибуллаевна'),
        ('10:15 - 11:50', 2, 'Системное программирование', '105', 'Атаев Ахмед Арсенович'),
        ('12:10 - 13:45', 3, 'Поддержка и тестирование программных модулей', '202', 'Багирова София Динмагомедовна'),
      ],
      DateTime.friday => [
        ('08:30 - 10:05', 1, 'Веб-программирование', '214', 'Хангишиева Аида Хабибуллаевна'),
        ('10:15 - 11:50', 2, 'Системное программирование', '105', 'Атаев Ахмед Арсенович'),
        ('12:10 - 13:45', 3, 'Физическая культура', 'спортзал', 'Козлов Игорь Иванович'),
      ],
      _ => <(String, int, String, String, String)>[],
    };

    return [
      for (final t in templates)
        _lessonRow(
          ymd: ymd,
          day: dayLabel,
          pair: t.$2,
          time: t.$1,
          subject: t.$3,
          room: t.$4,
          teacher: t.$5,
        ),
    ];
  }

  static Map<String, dynamic> _lessonRow({
    required String ymd,
    required String day,
    required int pair,
    required String time,
    required String subject,
    required String room,
    required String teacher,
  }) =>
      {
        'date': ymd,
        'day': day,
        'pair_number': pair,
        'time': time,
        'subject': subject,
        'room': room,
        'auditorium': room,
        'teacher': teacher,
        'week_type': 'Нечетная (1 неделя)',
        'subgroup': 0,
        'semester': '2025-2026',
      };

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static List<Map<String, dynamic>> _newsList() {
    final now = DateTime.now();
    return [
      _newsItem(1, now: now, title: 'Мобильное приложение колледжа ДГУ'),
      _newsItem(
        2,
        now: now.subtract(const Duration(days: 3)),
        title: 'График летней сессии опубликован',
      ),
    ];
  }

  static Map<String, dynamic> _newsItem(
    int id, {
    DateTime? now,
    String title = 'Новость колледжа',
  }) {
    final t = now ?? DateTime.now();
    return {
      'id': id,
      'title': title,
      'content': '<p>Информация для студентов колледжа ДГУ. Демонстрационная запись.</p>',
      'excerpt': title,
      'is_published': true,
      'created_at': t.toIso8601String(),
    };
  }

  static List<Map<String, dynamic>> _eventsList() {
    final start = DateTime.now().add(const Duration(days: 14));
    return [
      {
        'id': 1,
        'title': 'День открытых дверей',
        'description': 'Экскурсия по колледжу для абитуриентов и родителей.',
        'location': 'г. Махачкала, ул. Дзержинского, 21',
        'start_at': start.toIso8601String(),
        'end_at': start.add(const Duration(hours: 4)).toIso8601String(),
      },
    ];
  }

  static Map<String, dynamic> _help() => {
        'faq': [
          {
            'question': 'Как восстановить пароль?',
            'answer':
                'На экране входа нажмите «Забыли пароль» или обратитесь в учебный отдел колледжа.',
          },
          {
            'question': 'Где посмотреть расписание?',
            'answer':
                'В разделе «Расписание» приложения или в личном кабинете на сайте college.dgu.ru.',
          },
          {
            'question': 'Не приходят уведомления',
            'answer':
                'Проверьте настройки уведомлений в приложении и разрешения ОС для push.',
          },
        ],
        'hotline': '+7 (8722) 67-XX-XX',
        'email': 'colledgedsu@dgu.ru',
        'website_url': 'https://college.dgu.ru',
        'management_contacts': [
          {
            'unit_name': 'ФГБОУ ВО «Колледж ДГУ»',
            'head_full_name': 'Пирбудагова Диана Шамильевна',
            'address':
                '367000, Россия, Республика Дагестан, г. Махачкала, ул. Дзержинского 21',
            'email': 'collegedsu@mail.ru',
          },
        ],
      };

  static Map<String, dynamic> _notificationPrefs() => {
        'push_new_grades': true,
        'push_schedule_change': true,
        'push_assignment_deadlines': true,
        'push_college_news': true,
        'push_college_events': true,
        'push_department_announcements': true,
      };

  static List<Map<String, dynamic>> _assignments() {
    final dl = DateTime.now().add(const Duration(days: 7));
    return [
      {
        'id': 1,
        'title': 'Лабораторная: REST API',
        'subject': 'Веб-программирование',
        'description': 'Реализовать CRUD для учебного модуля.',
        'deadline_at': dl.toIso8601String(),
        'is_done': false,
      },
      {
        'id': 2,
        'title': 'Отчёт по тестированию',
        'subject': 'Поддержка и тестирование программных модулей',
        'description': 'Описать сценарии модульных тестов.',
        'deadline_at': dl.add(const Duration(days: 5)).toIso8601String(),
        'is_done': false,
      },
    ];
  }

  static List<Map<String, dynamic>> _lmsList() => [
        {
          'id': 1,
          'title': 'ЭБС «Юрайт»',
          'provider': 'urait',
          'url': 'https://urait.ru',
        },
        {
          'id': 2,
          'title': 'ПРОФ СПО',
          'provider': 'profspo',
          'url': 'https://profspo.ru',
        },
        {
          'id': 3,
          'title': 'Академия Москва',
          'provider': 'academy',
          'url': 'https://academymoscow.ru',
        },
      ];

  static List<Map<String, dynamic>> _portfolioItems() => [
        {
          'id': 1,
          'title': 'Мобильное приложение «Колледж ДГУ»',
          'category': 'project',
          'status': 'published',
          'created_at': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
        },
      ];

  static List<Map<String, dynamic>> _deptAnnouncements() {
    final t = DateTime.now().subtract(const Duration(days: 1));
    return [
      {
        'id': 1,
        'title': 'Консультации перед сессией',
        'body': 'Преподаватели отделения ИСиП проводят консультации по средам с 14:00 в ауд. 214.',
        'created_at': t.toIso8601String(),
        'is_read': false,
      },
    ];
  }

  static List<Map<String, dynamic>> _scholarshipCatalog() => [
        {'id': 'sport', 'title': 'Спортивные достижения', 'max_points': 10},
        {'id': 'science', 'title': 'Научная и проектная деятельность', 'max_points': 15},
        {'id': 'social', 'title': 'Общественная активность', 'max_points': 8},
      ];
}
