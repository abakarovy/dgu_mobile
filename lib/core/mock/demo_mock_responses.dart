import 'package:dio/dio.dart';

import 'demo_api_interceptor.dart';
import 'demo_session.dart';

/// Моковые тела ответов для [DemoSession].
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
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'id': 101,
          'name': 'ОИБАС-22',
          'code': 'ОИБАС-22',
        },
      );
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
      return DemoMockPayload(statusCode: 200, data: {'schedule': _scheduleForDate(ymd)});
    }
    if (path == '/1c/sync-grades') {
      return DemoMockPayload(statusCode: 200, data: _syncGrades());
    }
    if (path == '/1c/final-grades') {
      return DemoMockPayload(statusCode: 200, data: {'grades': []});
    }
    if (path == '/1c/curriculum') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'curriculum': {
            'title': 'Учебный план (демо)',
            'semesters': [
              {
                'name': '3 семестр',
                'disciplines': [
                  {'name': 'Базы данных', 'hours': 72},
                  {'name': 'Программирование', 'hours': 108},
                ],
              },
            ],
          },
          'is_cached': true,
        },
      );
    }
    if (path == '/1c/absences') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'semesters': [
            {
              'semester': '2025-2026, весна',
              'data': {'total_absences': 4},
            },
          ],
        },
      );
    }
    if (path == '/1c/student-photo') {
      return DemoMockPayload(statusCode: 404, data: {'detail': 'no photo'});
    }
    if (path == '/journal/grades/my') {
      return DemoMockPayload(statusCode: 200, data: []);
    }
    if (path == '/news' || path.startsWith('/news/')) {
      if (path.startsWith('/news/') && path != '/news') {
        final id = int.tryParse(path.split('/').last) ?? 1;
        final item = _newsItem(id);
        return DemoMockPayload(statusCode: 200, data: item);
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
      return DemoMockPayload(statusCode: 200, data: {'ticket': _studentTicket()});
    }
    if (path == '/mobile/assignments/my') {
      return DemoMockPayload(statusCode: 200, data: _assignments());
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
          'login_hint': 'Логин выдаётся в библиотеке',
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
        data: {'position': 12, 'total_students': 48, 'score': 24.5},
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
          'total_score': 18,
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
    // Неизвестные GET — пустой успех, чтобы экраны не падали.
    return DemoMockPayload(statusCode: 200, data: <String, dynamic>{});
  }

  static DemoMockPayload? _mutate(String path, String method, RequestOptions options) {
    if (path == '/auth/login') {
      return DemoMockPayload(statusCode: 200, data: DemoSession.demoUser.toJson());
    }
    if (path == '/students/me/wifi-password-request') {
      return DemoMockPayload(
        statusCode: 200,
        data: {'message': 'Заявка принята (демо-режим).'},
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
    if (path.startsWith('/portfolio/')) {
      return DemoMockPayload(statusCode: 200, data: {'ok': true});
    }
    if (path.startsWith('/scholarship-rating/')) {
      return DemoMockPayload(statusCode: 200, data: {'ok': true});
    }
    return DemoMockPayload(statusCode: 200, data: {'ok': true});
  }

  static Map<String, dynamic> _myProfile() => {
        'full_name': DemoSession.demoUser.fullName,
        'student_book_number': DemoSession.demoUser.studentBookNumber,
        'group': 'ОИБАС-22',
        'department': DemoSession.demoUser.department,
        'direction': DemoSession.demoUser.direction,
        'course': DemoSession.demoUser.course,
        'curator': 'Иванова Мария Петровна',
        'funding_type': 'Бюджет',
        'study_form': 'Очная',
        'status': 'Студент',
        'birth_date': '15.03.2006',
        'admission_year': '2022',
      };

  static Map<String, dynamic> _studentTicket() => {
        'full_name': DemoSession.demoUser.fullName,
        'student_book_number': DemoSession.demoUser.studentBookNumber,
        'birth_date': '15.03.2006',
        'department': DemoSession.demoUser.department,
        'study_group': 'ОИБАС-22',
        'admission_year': '2022',
        'study_form': 'Очная',
        'status': 'Студент',
        'course': DemoSession.demoUser.course,
      };

  static Map<String, dynamic> _syncGrades() {
    final now = DateTime.now();
    return {
      'grades': [
        {
          'semester': '2025-2026, весна',
          'records': [
            {
              'subject': 'Базы данных',
              'grade': '5',
              'type': 'Контрольная',
              'date': now.subtract(const Duration(days: 3)).toIso8601String(),
              'teacher_name': 'Петров А.С.',
            },
            {
              'subject': 'Программирование',
              'grade': '4',
              'type': 'Практика',
              'date': now.subtract(const Duration(days: 10)).toIso8601String(),
              'teacher_name': 'Сидорова Е.В.',
            },
            {
              'subject': 'История',
              'grade': '5',
              'type': 'Зачёт',
              'date': now.subtract(const Duration(days: 20)).toIso8601String(),
            },
          ],
        },
        {
          'semester': '2025-2026, осень',
          'records': [
            {
              'subject': 'Математика',
              'grade': '4',
              'type': 'Экзамен',
              'date': now.subtract(const Duration(days: 90)).toIso8601String(),
            },
          ],
        },
      ],
    };
  }

  static List<Map<String, dynamic>> _scheduleForDate(String ymd) {
    final parsed = DateTime.tryParse(ymd);
    if (parsed == null) return [];
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return [];
    }
    final dot = '${day.day.toString().padLeft(2, '0')}.'
        '${day.month.toString().padLeft(2, '0')}.'
        '${day.year}';
    final seed = day.weekday;
    return [
      {
        'pair_number': 1,
        'subject': seed.isOdd ? 'Математика' : 'Базы данных',
        'start_time': '08:30',
        'end_time': '10:00',
        'teacher': 'Петров А.С.',
        'auditorium': '201',
        'date': dot,
      },
      {
        'pair_number': 2,
        'subject': 'Программирование',
        'start_time': '10:15',
        'end_time': '11:45',
        'teacher': 'Сидорова Е.В.',
        'auditorium': '105',
        'date': dot,
      },
      if (seed <= 5)
        {
          'pair_number': 3,
          'subject': 'Физическая культура',
          'start_time': '12:00',
          'end_time': '13:30',
          'teacher': 'Козлов И.И.',
          'auditorium': 'спортзал',
          'date': dot,
        },
    ];
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static List<Map<String, dynamic>> _newsList() {
    final now = DateTime.now();
    return [
      _newsItem(1, now: now),
      _newsItem(
        2,
        now: now.subtract(const Duration(days: 2)),
        title: 'Расписание на неделю обновлено',
      ),
    ];
  }

  static Map<String, dynamic> _newsItem(
    int id, {
    DateTime? now,
    String title = 'Добро пожаловать в приложение колледжа ДГУ',
  }) {
    final t = now ?? DateTime.now();
    return {
      'id': id,
      'title': title,
      'content': '<p>Это демонстрационная новость для тестового аккаунта.</p>',
      'excerpt': 'Демо-режим приложения',
      'is_published': true,
      'created_at': t.toIso8601String(),
    };
  }

  static List<Map<String, dynamic>> _eventsList() {
    final start = DateTime.now().add(const Duration(days: 7));
    return [
      {
        'id': 1,
        'title': 'День открытых дверей',
        'description': 'Приглашаем абитуриентов на экскурсию по колледжу.',
        'location': 'Главный корпус',
        'start_at': start.toIso8601String(),
        'end_at': start.add(const Duration(hours: 3)).toIso8601String(),
      },
    ];
  }

  static Map<String, dynamic> _help() => {
        'hotline_phone': '+7 (8722) 00-00-00',
        'email': 'info@college.dgu.ru',
        'website_url': 'https://college.dgu.ru',
        'faq': [
          {
            'title': 'Как войти в приложение?',
            'answer': 'Используйте e-mail и пароль, выданные в приёмной комиссии, '
                'или зарегистрируйтесь по номеру зачётной книжки.',
          },
          {
            'title': 'Демо-аккаунт',
            'answer': 'Для проверки: test@test.ru / test1234 (только демо-данные).',
          },
        ],
      };

  static Map<String, dynamic> _notificationPrefs() => {
        'push_new_grades': true,
        'push_schedule_change': true,
        'push_assignment_deadlines': true,
        'push_college_news': true,
        'push_college_events': false,
      };

  static List<Map<String, dynamic>> _assignments() {
    final dl = DateTime.now().add(const Duration(days: 5));
    return [
      {
        'id': 1,
        'title': 'Лабораторная №3',
        'subject': 'Базы данных',
        'description': 'Подготовить отчёт по нормализации.',
        'deadline_at': dl.toIso8601String(),
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
      ];

  static List<Map<String, dynamic>> _portfolioItems() => [
        {
          'id': 1,
          'title': 'Дипломный проект (черновик)',
          'category': 'project',
          'status': 'draft',
          'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
      ];

  static List<Map<String, dynamic>> _deptAnnouncements() {
    final t = DateTime.now().subtract(const Duration(hours: 5));
    return [
      {
        'id': 1,
        'title': 'Собрание студентов 2 курса',
        'body': '15 июня в 14:00, ауд. 201. Явка обязательна.',
        'created_at': t.toIso8601String(),
        'is_read': false,
      },
    ];
  }

  static List<Map<String, dynamic>> _scholarshipCatalog() => [
        {
          'id': 'sport',
          'title': 'Спортивные достижения',
          'max_points': 10,
        },
        {
          'id': 'science',
          'title': 'Научная деятельность',
          'max_points': 15,
        },
      ];
}
