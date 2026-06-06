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
    if (path == '/v1/user/profile') {
      return DemoMockPayload(statusCode: 200, data: _staffUser());
    }
    if (path == '/v1/staff/capabilities') {
      return DemoMockPayload(statusCode: 200, data: _staffCapabilities());
    }
    if (path == '/v1/admin/applicants') {
      return DemoMockPayload(statusCode: 200, data: _staffApplicants());
    }
    if (path.startsWith('/v1/admin/applicants/')) {
      final id = int.tryParse(path.split('/').last) ?? 1;
      return DemoMockPayload(statusCode: 200, data: _staffApplicantDetail(id));
    }
    if (path == '/v1/admin/payment-cutoff') {
      return DemoMockPayload(statusCode: 200, data: {'cutoff_score': 4.35});
    }
    if (path == '/mobile/events/admin/list') {
      return DemoMockPayload(statusCode: 200, data: _staffEventsAdmin());
    }
    if (path == '/mobile-app-release/admin') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'check_updates_on_launch': true,
          'latest_version': '1.1.1',
          'min_version': '1.1.1',
          'force_update': true,
          'update_title': 'Доступно обновление',
          'update_message': 'Что нового в этой версии…',
          'store_url_rustore':
              'https://www.rustore.ru/catalog/app/ru.dgu.college.dgu_mobile.android',
          'store_url_ios': 'https://apps.apple.com/us/app/',
          'store_url_android':
              'https://play.google.com/store/apps/details?id=ru.dgu.college.dgu_mobile.android',
          'updated_at': '2026-06-04T14:56:34',
        },
      );
    }
    if (path == '/admin/dashboard-stats') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'users_total': 393,
          'users_new_week': 380,
          'students_count': 379,
          'teachers_count': 2,
          'department_heads_count': 3,
          'admins_count': 5,
          'news_published': 3,
          'news_total': 3,
          'news_unpublished': 0,
          'news_published_week': 3,
          'groups_total': 1,
          'groups_new_week': 0,
          'portfolio_pending': 0,
          'document_requests_pending': 7,
          'materials_total': 0,
          'upk_services': 1,
          'upk_services_active': 1,
          'upk_cases': 0,
          'clients': {
            'registered_web': 10,
            'registered_mobile': 182,
            'registered_admin': 0,
            'registered_invite': 1,
            'logins_week': 17,
            'logins_mobile': 12,
            'logins_web': 5,
            'mobile_app_opens_week': 203,
          },
          'registrations_by_source_week': [
            {'label': 'Не указано', 'count': 187},
            {'label': 'Мобильное приложение', 'count': 182},
            {'label': 'Сайт', 'count': 10},
            {'label': 'Приглашение', 'count': 1},
          ],
          'registrations_by_source_total': [
            {'label': 'Не указано', 'count': 200},
            {'label': 'Мобильное приложение', 'count': 182},
            {'label': 'Сайт', 'count': 10},
            {'label': 'Приглашение', 'count': 1},
          ],
          'logins_by_client_week': [
            {'label': 'Не указано', 'count': 12},
            {'label': 'Сайт', 'count': 5},
          ],
          'registrations_by_client_week': [
            {'label': 'Мобильное приложение', 'count': 109},
            {'label': 'Сайт', 'count': 3},
          ],
          'app_versions_week': [
            {'label': '1.1.1', 'count': 195},
            {'label': '1.1.0', 'count': 8},
          ],
          'mobile_app_by_platform': [
            {'label': 'iOS', 'count': 113},
            {'label': 'Android', 'count': 89},
            {'label': 'windows', 'count': 1},
          ],
        },
      );
    }
    if (path == '/journal/subjects/my') {
      return DemoMockPayload(
        statusCode: 200,
        data: [
          {'id': 1, 'name': 'Информатика', 'group_code': 'ИС-201'},
        ],
      );
    }
    if (path == '/cabinet/department/me') {
      return DemoMockPayload(
        statusCode: 200,
        data: {'department_name': 'Отделение информационных технологий'},
      );
    }
    if (path == '/cabinet/department/groups-overview') {
      return DemoMockPayload(
        statusCode: 200,
        data: [
          {'group_code': 'ИС-201', 'students_count': 28},
        ],
      );
    }
    if (path == '/cabinet/department/announcements') {
      return DemoMockPayload(statusCode: 200, data: []);
    }
    if (path == '/news/admin/list') {
      return DemoMockPayload(
        statusCode: 200,
        data: [
          {'id': 1, 'title': 'Демо-новость', 'created_at': '2026-05-01'},
        ],
      );
    }
    if (path == '/users') {
      if (options.method == 'POST') {
        return DemoMockPayload(statusCode: 201, data: {'id': 99, ...?options.data});
      }
      return DemoMockPayload(
        statusCode: 200,
        data: [
          {
            'id': 1,
            'full_name': 'Студент Демо',
            'email': 'test@test.ru',
            'role': 'student',
            'is_test_user': true,
            'is_active': true,
            'force_password_change': true,
          },
          {
            'id': 2,
            'full_name': 'Ягияев Али',
            'email': 'ali.yagiyaev@yandex.ru',
            'role': 'student',
            'status': 'active',
          },
          {
            'id': 3,
            'full_name': 'Гаджилаев Магомедгаджи',
            'email': 'info@gadzhilaev.ru',
            'role': 'admin',
            'status': 'inactive',
            'is_active': false,
          },
        ],
      );
    }
    if (path.startsWith('/users/') && options.method == 'PUT') {
      return DemoMockPayload(statusCode: 200, data: options.data ?? {});
    }
    if (path.startsWith('/users/') && options.method == 'DELETE') {
      return DemoMockPayload(statusCode: 204, data: null);
    }
    if (path == '/groups') {
      if (options.method == 'POST') {
        final body = options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : <String, dynamic>{};
        return DemoMockPayload(
          statusCode: 201,
          data: {
            'id': 99,
            'teacher_id': body['teacher_id'] ?? 2,
            'students_count': 0,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            ...body,
          },
        );
      }
      return DemoMockPayload(
        statusCode: 200,
        data: [
          {
            'id': 1,
            'name': 'ОИБАС 3к 1г 2023',
            'teacher_id': 2,
            'teacher_name': 'Ягияев Али',
            'students_count': 8,
            'status': 'active',
            'description': 'Создана автоматически из сводки отделения 1С',
            'course': 3,
            'direction': 'ОИБАС',
          },
        ],
      );
    }
    if (path.startsWith('/groups/') && path.endsWith('/students')) {
      return DemoMockPayload(
        statusCode: 200,
        data: [
          {
            'id': 101,
            'full_name': 'АХМЕДОВА ДЖАМИЛЯ КАМИЛЬЕВНА',
            'email': 'jamila@demo.ru',
            'role': 'student',
          },
          {
            'id': 102,
            'full_name': 'СИДИКОВ СОДИРХОН БАХТИЁРОВИЧ',
            'email': 'sodir@demo.ru',
            'role': 'student',
          },
        ],
      );
    }
    if (RegExp(r'^/groups/\d+/students/\d+').hasMatch(path)) {
      return DemoMockPayload(statusCode: 200, data: {});
    }
    if (RegExp(r'^/groups/\d+').hasMatch(path)) {
      if (options.method == 'PUT') {
        return DemoMockPayload(statusCode: 200, data: options.data ?? {});
      }
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'id': 1,
          'name': 'ОИБАС 3к 1г 2023',
          'teacher_id': 2,
          'students_count': 8,
          'description': 'Создана автоматически из сводки отделения 1С',
          'course': 3,
          'direction': 'ОИБАС',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }
    if (path == '/portfolio/admin/pending') {
      return const DemoMockPayload(statusCode: 200, data: <dynamic>[]);
    }
    if (path == '/admin/settings') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'email_notifications': true,
          'upk_cases_public': true,
          'student_registration_enabled': true,
          'maintenance_mode': false,
          'auto_publish_news': true,
        },
      );
    }
    if (path == '/edu-disclosure/admin/sections') {
      return DemoMockPayload(
        statusCode: 200,
        data: [
          {'slug': 'mto', 'title': 'МТО — материально-техническое обеспечение'},
          {'slug': 'about', 'title': 'О колледже'},
        ],
      );
    }
    if (path == '/admin/weekly-grades-digest/preview') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'week_label': '1–7 июня 2026',
          'week_start': '2026-06-01',
          'week_end': '2026-06-07',
          'student_name': 'Студент Демо',
          'rows': [
            {
              'date': '2026-06-03',
              'subject_name': 'Математика',
              'grade_type': 'Текущая',
              'grade_value': '5',
            },
          ],
        },
      );
    }
    if (path == '/admin/weekly-grades-digest/send-student') {
      return DemoMockPayload(
        statusCode: 200,
        data: {'ok': true, 'message': 'Письмо отправлено', 'emails_sent': 1},
      );
    }
    if (path == '/admin/weekly-grades-digest/send-broadcast') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'week_label': '1–7 июня 2026',
          'emails_sent': 12,
          'emails_failed': 0,
          'students_processed': 15,
          'students_skipped_no_book': 0,
          'students_no_grades_in_week': 3,
        },
      );
    }
    if (path == '/admin/weekly-grades-digest/recipients') {
      return DemoMockPayload(
        statusCode: 200,
        data: [
          {
            'value': '1',
            'student_user_id': 1,
            'line': 'Студент Демо · test@test.ru',
          },
        ],
      );
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
      return DemoMockPayload(statusCode: 200, data: _finalGrades());
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
      return DemoMockPayload(statusCode: 200, data: _journalGradesMy());
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
    if (path == '/edu-disclosure') {
      return DemoMockPayload(statusCode: 200, data: _eduDisclosure());
    }
    if (path == '/upbringing') {
      return DemoMockPayload(statusCode: 200, data: _upbringing());
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
      return DemoMockPayload(statusCode: 200, data: _portfolioSelfUploads());
    }
    if (path == '/portfolio/my-complete') {
      return DemoMockPayload(statusCode: 200, data: _portfolioComplete());
    }
    if (path == '/portfolio/rating') {
      return DemoMockPayload(
        statusCode: 200,
        data: {'total_points': 12},
      );
    }
    if (path == '/portfolio/share') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'enabled': true,
          'public_url': 'https://college.dgu.ru/portfolio/demo-student',
        },
      );
    }
    if (path == '/students/department-announcements/my') {
      final archive = options.queryParameters['archive']?.toString() == 'true';
      return DemoMockPayload(
        statusCode: 200,
        data: archive ? _deptAnnouncementsArchive() : _deptAnnouncements(),
      );
    }
    if (path == '/scholarship-rating/catalog') {
      return DemoMockPayload(statusCode: 200, data: _scholarshipCatalog());
    }
    if (path == '/scholarship-rating/my/summary') {
      return DemoMockPayload(statusCode: 200, data: _scholarshipSummary());
    }
    if (path == '/student-portal') {
      return DemoMockPayload(statusCode: 200, data: _studentPortal());
    }
    if (path == '/health') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'status': 'ok',
          'demo': true,
          'app_update': {
            'update_available': false,
          },
        },
      );
    }
    return DemoMockPayload(statusCode: 200, data: <String, dynamic>{});
  }

  static DemoMockPayload? _mutate(String path, String method, RequestOptions options) {
    if (path == '/v1/auth/staff') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'token': DemoSession.demoToken,
          'user': _staffUser(),
        },
      );
    }
    if (path == '/v1/auth/web-handoff') {
      final body = options.data;
      final target = body is Map ? (body['target'] ?? 'news_edit') : 'news_edit';
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'url':
              'https://college.dgu.ru/auth/mobile-handoff?code=demo-handoff&target=$target',
        },
      );
    }
    if (path == '/v1/user/avatar') {
      return DemoMockPayload(
        statusCode: 200,
        data: {'avatar_url': '/uploads/avatars/demo_staff.jpg'},
      );
    }
    if (path == '/v1/admin/set-payment-cutoff') {
      return DemoMockPayload(
        statusCode: 200,
        data: {
          'cutoff_score': 4.35,
          'moved_to_payment_count': 3,
          'push_sent': 2,
          'push_failed': 0,
        },
      );
    }
    if (path == '/mobile-app-release/admin' && method == 'PUT') {
      final body = options.data;
      return DemoMockPayload(
        statusCode: 200,
        data: body is Map ? Map<String, dynamic>.from(body) : {'ok': true},
      );
    }
    if (path.startsWith('/mobile/events/') && method == 'DELETE') {
      return DemoMockPayload(statusCode: 200, data: {'ok': true});
    }
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
    if (path == '/scholarship-rating/staff/pending') {
      return const DemoMockPayload(statusCode: 200, data: <dynamic>[]);
    }
    if (path == '/scholarship-rating/staff/approved') {
      return const DemoMockPayload(statusCode: 200, data: <dynamic>[]);
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
              {
                'subject': 'История',
                'grade': '2',
                'type': 'Экзамен',
                'date': '2025-06-22',
              },
            ],
          },
        ],
      };

  /// Журнал без сессионных типов (как после нормализации бэкенда).
  static List<Map<String, dynamic>> _journalGradesMy() => [
        {
          'subject_name': 'Веб-программирование',
          'grade_value': 4,
          'grade_type': 'Контрольная работа',
          'date': '2026-04-15',
          'semester': '2 сем 2025-2026',
        },
        {
          'subject_name': 'Системное программирование',
          'grade_value': 5,
          'grade_type': 'Ответ у доски',
          'date': '2026-04-22',
          'semester': '2 сем 2025-2026',
        },
        {
          'subject_name': 'Математика',
          'grade_value': 4,
          'grade_type': 'Контрольная работа',
          'date': '2025-11-12',
          'semester': '1 сем 2025-2026',
        },
        {
          'subject_name': 'Физика',
          'grade_value': 5,
          'grade_type': 'Лабораторная',
          'date': '2025-10-20',
          'semester': '1 сем 2025-2026',
        },
      ];

  /// Итоговые ведомости сессии — отдельный API.
  static Map<String, dynamic> _finalGrades() => {
        'grades': [
          {
            'subject': 'Операционные системы',
            'control_type': 'Экзамен (балльная шкала)',
            'grade': '5',
            'date': '2026-05-23',
            'semester': '2 сем 2025-2026',
          },
          {
            'subject': 'Базы данных',
            'control_type': 'Экзамен (балльная шкала)',
            'grade': '5',
            'date': '2026-05-23',
            'semester': '2 сем 2025-2026',
          },
          {
            'subject': 'История',
            'control_type': 'Экзамен (балльная шкала)',
            'grade': '5',
            'date': '2025-06-22',
            'semester': '2 сем 2024-2025',
          },
          {
            'subject': 'Безопасность жизнедеятельности',
            'control_type': 'Зачёт',
            'grade': '5',
            'date': '2025-06-18',
            'semester': '2 сем 2024-2025',
          },
          {
            'subject': 'Математика',
            'control_type': 'Экзамен (балльная шкала)',
            'grade': '4',
            'date': '2026-01-20',
            'semester': '1 сем 2025-2026',
          },
        ],
        'is_cached': false,
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

  static Map<String, dynamic> _eduDisclosure() => {
        'basic': {
          'org_created_date': '1967',
          'founders': 'Министерство науки и высшего образования Российской Федерации',
          'work_schedule': 'Пн–Пт: 9:00–18:00',
          'phones': '+7 (872) 267-00-00',
          'email': 'college@dgu.ru',
        },
        'basic_location_branches': {
          'body_html':
              '<p>367000, Республика Дагестан, г. Махачкала, ул. Дзержинского, 21</p>',
        },
        'struktura_kolledzha': {
          'body_html':
              '<p>Структура и органы управления образовательной организацией.</p>',
        },
        'management_units': [
          {
            'unit_name': 'ФГБОУ ВО «Колледж ДГУ»',
            'head_full_name': 'Пирбудагова Диана Шамильевна',
            'address': 'г. Махачкала, ул. Дзержинского 21',
            'email': 'collegedsu@mail.ru',
          },
        ],
        'documents': [
          {
            'title': 'Устав образовательной организации',
            'file_url': '/uploads/edu_disclosure/demo-ustav.pdf',
          },
        ],
        'education': {
          'intro':
              '<p>Колледж реализует программы среднего профессионального образования по очной форме.</p>',
        },
        'fgos_standards': [
          {
            'title': 'ФГОС СПО по специальности 09.02.07',
            'file_url': '/uploads/edu_disclosure/demo-fgos.pdf',
          },
        ],
        'staff': [
          {
            'full_name': 'Иванов Иван Иванович',
            'position': 'Преподаватель',
            'subjects': 'Информатика',
          },
        ],
        'mto': {
          'libraries':
              '<p>Библиотечный фонд колледжа включает учебную и научную литературу.</p>',
        },
        'scholarship': {
          'scholarships':
              '<p>Информация о стипендиях и мерах поддержки обучающихся публикуется на сайте колледжа.</p>',
        },
        'paid_services': {
          'procedure': '<p>Порядок оказания платных образовательных услуг.</p>',
        },
        'finance': {
          'activity_volume':
              '<p>Сведения о финансово-хозяйственной деятельности размещены в соответствии с требованиями законодательства.</p>',
        },
        'vacant': {
          'admission_tables':
              '<p>Информация о вакантных местах для приёма обновляется в период приёмной кампании.</p>',
        },
        'vacant_seats': [
          {
            'program_name': 'Информационная безопасность',
            'level': 'СПО',
            'form': 'Очная',
            'vacant_count': 25,
          },
        ],
      };

  static Map<String, dynamic> _upbringing() => {
        'categories': [
          {
            'key': 'extremism',
            'title': 'Противодействие экстремизму и терроризму',
            'entries': [
              {
                'id': 1,
                'category': 'extremism',
                'title': 'Методические материалы',
                'body_html': '<p>Демо-материал воспитательной работы.</p>',
                'file_url': null,
                'sort_order': 0,
              },
            ],
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

  static List<Map<String, dynamic>> _portfolioSelfUploads() => [
        {
          'id': 1,
          'file_name': 'Сертификат Python.pdf',
          'section': 'certificate',
          'status': 'approved',
          'description': 'Онлайн-курс программирования',
          'points': 5,
        },
        {
          'id': 2,
          'file_name': 'Грамота_олимпиада.jpg',
          'section': 'diploma',
          'status': 'approved',
          'description': 'Региональная олимпиада по информатике',
          'points': 7,
        },
        {
          'id': 3,
          'file_name': 'Лабораторная_мобильные.docx',
          'section': 'general',
          'status': 'pending',
          'description': 'Отчёт по разработке приложения',
        },
      ];

  static Map<String, dynamic> _portfolioComplete() => {
        'self_uploads': _portfolioSelfUploads(),
        'official_final_works': [
          {
            'id': 101,
            'subject_name': 'Веб-программирование',
            'work_type': 'coursework',
            'original_filename': 'Курсовая_Веб.pdf',
            'upload_deadline_at': '2026-06-15T23:59:00Z',
            'is_past_deadline': false,
          },
          {
            'id': 102,
            'subject_name': 'Разработка мобильных приложений',
            'work_type': 'individual_project',
            'original_filename': 'Проект_мобильное_приложение.pdf',
            'upload_deadline_at': '2026-05-01T23:59:00Z',
            'is_past_deadline': true,
          },
        ],
      };

  static List<Map<String, dynamic>> _deptAnnouncements() {
    final t = DateTime.now().subtract(const Duration(days: 1));
    final t2 = DateTime.now().subtract(const Duration(hours: 8));
    return [
      {
        'id': 1,
        'title': 'Консультации перед сессией',
        'body':
            'Преподаватели отделения ИСиП проводят консультации по средам с 14:00 в ауд. 214. '
            'Запись у куратора группы.',
        'group_code': DemoPersona.studyGroup,
        'created_at': t.toIso8601String(),
        'is_read': false,
      },
      {
        'id': 2,
        'title': 'Сдача итоговых работ',
        'body':
            'Курсовые и индивидуальные проекты принимаются до 15 июня. '
            'Файлы загружайте в раздел «Портфолио».',
        'group_code': DemoPersona.studyGroup,
        'created_at': t2.toIso8601String(),
        'is_read': true,
      },
    ];
  }

  static List<Map<String, dynamic>> _deptAnnouncementsArchive() {
    final t = DateTime.now().subtract(const Duration(days: 45));
    return [
      {
        'id': 10,
        'title': 'Расписание зимней сессии',
        'body': 'График экзаменов опубликован на портале колледжа.',
        'group_code': DemoPersona.studyGroup,
        'created_at': t.toIso8601String(),
        'is_read': true,
      },
    ];
  }

  /// Каталог стипендии: вложенная структура `categories → sections → criteria`.
  static Map<String, dynamic> _scholarshipCatalog() => {
        'categories': [
          {
            'id': 'study',
            'short': 'Учёба',
            'sections': [
              {
                'id': '1.1',
                'title': 'Успеваемость и дисциплина',
                'criteria': [
                  {
                    'id': 'study_gpa',
                    'label': 'Средний балл без «удовл.» и «неуд.»',
                    'points': 10,
                    'allow_upload': false,
                  },
                  {
                    'id': 'study_attendance',
                    'label': 'Посещаемость без пропусков',
                    'points': 5,
                    'allow_upload': false,
                  },
                ],
              },
            ],
          },
          {
            'id': 'science',
            'short': 'Наука и проекты',
            'sections': [
              {
                'id': '2.1',
                'title': 'Научные и проектные работы',
                'criteria': [
                  {
                    'id': 'science_project',
                    'label': 'Участие в проекте / хакатоне',
                    'points': 15,
                    'allow_upload': true,
                    'divide_by_coauthors': true,
                  },
                ],
              },
            ],
          },
          {
            'id': 'sport',
            'short': 'Спорт',
            'sections': [
              {
                'id': '3.1',
                'title': 'Спортивные достижения',
                'criteria': [
                  {
                    'id': 'sport_medal',
                    'label': 'Призовое место на соревнованиях',
                    'points': 10,
                    'allow_upload': true,
                  },
                ],
              },
            ],
          },
        ],
      };

  static Map<String, dynamic> _scholarshipSummary() => {
        'academic_year': '2025-2026',
        'semester': 'spring',
        'total_approved': 18,
        'category_totals': {
          'study': 8,
          'science': 6,
          'sport': 4,
        },
        'entries': [
          {
            'id': 501,
            'status': 'approved',
            'approved_points': 6,
            'criterion_ref': 'science_project',
            'notes': 'Хакатон «Цифровой Дагестан»',
          },
          {
            'id': 502,
            'status': 'pending',
            'suggested_points': 4,
            'criterion_ref': 'sport_medal',
            'notes': 'Справка о соревнованиях',
          },
        ],
      };

  static Map<String, dynamic> _studentPortal() => {
        'overview': {
          'body_html':
              '<p>На портале колледжа собраны расписания, материалы для подготовки к ВПР, '
              'ссылки на электронные ресурсы и полезные разделы для студентов СПО.</p>',
          'hub_links': [
            {
              'label': 'Стипендия и материальная поддержка',
              'href': '/svedeniya/students/scholarships/',
              'external': false,
            },
            {
              'label': 'Общежитие',
              'href': '/svedeniya/students/dormitory/',
              'external': false,
            },
            {
              'label': 'Сайт колледжа',
              'href': 'https://college.dgu.ru',
              'external': true,
            },
          ],
        },
        'schedule_semesters': [
          {
            'title': '1 семестр 2025–2026',
            'entries': [
              {
                'label': 'Расписание очного отделения',
                'original_filename': 'raspisanie_osen_2025.pdf',
                'file_url': '/uploads/demo/raspisanie_osen_2025.pdf',
              },
              {
                'label': 'Расписание заочного отделения',
                'original_filename': 'raspisanie_zaochnoe.pdf',
                'file_url': '/uploads/demo/raspisanie_zaochnoe.pdf',
              },
            ],
          },
          {
            'title': '2 семестр 2025–2026',
            'entries': [
              {
                'label': 'Расписание очное (весна)',
                'original_filename': 'raspisanie_vesna_2026.pdf',
                'file_url': '/uploads/demo/raspisanie_vesna_2026.pdf',
              },
            ],
          },
        ],
        'vpr': {
          'page_title': 'Внутренние промежуточные работы (ВПР)',
          'body_html':
              '<p>Материалы для подготовки к внутренним промежуточным работам по дисциплинам '
              'общеобразовательного цикла.</p>',
          'original_filename': 'vpr_materials_2026.pdf',
          'file_url': '/uploads/demo/vpr_materials_2026.pdf',
        },
        'schedule_page': {'body_html': ''},
        'sessions': {'body_html': ''},
        'sessions_semesters': [],
        'eresources': {
          'body_html':
              '<h2>Электронные ресурсы</h2><ul>'
              '<li><a href="https://urait.ru/">ЭБС «Юрайт»</a></li>'
              '<li><a href="https://profspo.ru/">ПРОФ СПО</a></li>'
              '</ul>',
        },
      };

  static Map<String, dynamic> _staffUser() => {
        'id': 9001,
        'fio': 'Демо Администратор',
        'email': 'staff-demo@dgu.ru',
        'role': 'admin',
        'is_admin': true,
        'can_access_site_admin': true,
        'can_access_admission_admin': true,
        'can_access_department_cabinet': false,
        'is_teacher': false,
        'position': 'Администрация колледжа',
        'avatar_url': null,
      };

  static Map<String, dynamic> _staffCapabilities() => {
        'role': 'admin',
        'is_admin': true,
        'can_access_site_admin': true,
        'can_access_admission_admin': true,
        'can_access_department_cabinet': false,
        'is_teacher': false,
        'modules': [
          {
            'id': 'profile',
            'label': 'Профиль и аватар',
            'mobile_ready': 'full',
          },
          {
            'id': 'admission_campaign',
            'label': 'Приёмная кампания',
            'mobile_ready': 'full',
          },
          {
            'id': 'events',
            'label': 'Мероприятия',
            'mobile_ready': 'full',
          },
          {
            'id': 'dashboard',
            'label': 'Дашборд',
            'mobile_ready': 'full',
          },
          {
            'id': 'news',
            'label': 'Новости',
            'mobile_ready': 'full',
          },
          {
            'id': 'users',
            'label': 'Пользователи',
            'mobile_ready': 'full',
          },
          {
            'id': 'groups',
            'label': 'Группы',
            'mobile_ready': 'full',
          },
          {
            'id': 'moderation',
            'label': 'Модерация',
            'mobile_ready': 'full',
          },
          {
            'id': 'weekly_grades',
            'label': 'Рассылка оценок',
            'mobile_ready': 'full',
          },
          {
            'id': 'scholarship_rating',
            'label': 'Стипендиальный рейтинг',
            'mobile_ready': 'full',
          },
          {
            'id': 'mobile_app',
            'label': 'Мобильное приложение',
            'mobile_ready': 'full',
          },
        ],
      };

  static List<Map<String, dynamic>> _staffEventsAdmin() => [
        {
          'id': 1,
          'title': 'День открытых дверей',
          'start_at': '2026-06-01T10:00:00',
          'location': 'Колледж ДГУ',
        },
      ];

  static Map<String, dynamic> _staffApplicants() => {
        'items': [
          {
            'id': 1,
            'full_name': 'Иванов Иван Иванович',
            'exam_score': 4.52,
            'status': 'registered',
          },
          {
            'id': 2,
            'full_name': 'Петрова Анна Сергеевна',
            'exam_score': 4.10,
            'status': 'payment_list',
          },
        ],
        'total': 2,
      };

  static Map<String, dynamic> _staffApplicantDetail(int id) => {
        'id': id,
        'full_name': 'Иванов Иван Иванович',
        'email': 'ivanov@mail.ru',
        'phone': '+79001234567',
        'phone_extra': null,
        'exam_score': 4.52,
        'status': 'registered',
      };
}
