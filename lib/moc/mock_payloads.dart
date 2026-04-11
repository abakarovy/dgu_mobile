import 'dart:convert';
import 'dart:typed_data';

import 'mock_accounts.dart';

/// JSON-ответы мокового API (один студент: Али Ягияев).
abstract final class MockPayloads {
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _ddMmYyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  // (intentionally no unused helpers here; payloads are shaped to backend logs)

  static Map<String, dynamic> oneCProfile(int userId) {
    // Под форму ответа, которая видна в логах:
    // {is_cached, student_id, last_name, first_name, middle_name, birthday(dd.MM.yyyy),
    //  direction, group, department, education_form, admission_year, course, curator,
    //  social_role, status, funding_type, student_book_number, study_form, full_name, grades:[...]}
    return {
      'is_cached': true,
      'student_id': 23385,
      'last_name': 'ЯГИЯЕВ',
      'first_name': 'АЛИ',
      'middle_name': 'ТАЖУТДИНОВИЧ',
      'birthday': '10.09.2007',
      'direction': '10.02.05 Обеспечение информационной безопасности автоматизированных систем',
      'group': 'ОИБАС 3к 1г 2023',
      'department': 'Обеспечение информационной безопасности автоматизированных систем',
      'education_form': 'Очная форма обучения',
      'admission_year': '2023',
      'course': 3,
      'curator': 'Шахбанова Марият Ибрагимбековна',
      'social_role': '',
      'status': 'Обучается',
      'funding_type': 'Бюджетное финансирование',
      'student_book_number': '23385',
      'study_form': 'Очная форма обучения',
      'full_name': 'ЯГИЯЕВ АЛИ ТАЖУТДИНОВИЧ',
      'grades': syncGrades(userId)['grades'],
    };
  }

  static Map<String, dynamic> studentTicket(int userId) {
    // Под форму ответа в логах:
    // {full_name, student_book_number, ticket_valid_until, ticket_issued_at, study_form, course}
    final p = oneCProfile(userId);
    return {
      'full_name': p['full_name'],
      'student_book_number': p['student_book_number'],
      'ticket_valid_until': null,
      'ticket_issued_at': null,
      'study_form': p['study_form'],
      'course': p['course'],
    };
  }

  static Map<String, dynamic> groupMy(int userId) {
    // В логах `/groups/my` вернул `[]`.
    return {};
  }

  static List<dynamic> newsList(int userId) {
    // Под форму ответа в логах (список объектов).
    return [
      {
        'title': 'День открытых дверей (мок)',
        'content': 'Приходите смотреть (мок).',
        'excerpt': 'День открытых дверей',
        // Локальный ассет — [NewsModel.bundleAssetPath] / карточка новости.
        'image_url': 'assets/images/img1.png',
        'id': 11,
        'author_id': 7,
        'is_published': true,
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'updated_at': null,
      },
      {
        'title': 'Студвесна (мок)',
        'content': 'Приходите смотреть, Али.',
        'excerpt': 'Студвесна в колледже ДГУ',
        'image_url': 'assets/images/img2.png',
        'id': 10,
        'author_id': 7,
        'is_published': true,
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'updated_at': null,
      },
    ];
  }

  static List<dynamic> eventsList(int userId) {
    // Под форму ответа в логах:
    // {id,title,description,image_url,location,starts_at,ends_at,is_published,created_at}
    final start = DateTime.now().add(const Duration(days: 7));
    return [
      {
        'id': 1,
        'title': 'Мероприятие (мок)',
        'description': 'Описание мероприятия (мок).',
        'image_url': null,
        'location': 'Колледж ДГУ',
        'starts_at': start.toIso8601String(),
        'ends_at': null,
        'is_published': true,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  static Map<String, dynamic> eventById(int id) {
    return {
      'id': id,
      'title': 'Мероприятие #$id (мок)',
      'description': 'Описание демонстрационного мероприятия.',
      'image_url': null,
      'location': 'Колледж ДГУ',
      'starts_at': DateTime.now().toIso8601String(),
      'ends_at': null,
      'is_published': true,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static List<dynamic> assignments(int userId) {
    // Оставляем как есть — приложению достаточно списка; формат близкий к `/api/mobile/assignments/my`.
    const subj = 'Сети и системы передачи информации';
    return [
      {
        'id': 9001,
        'title': 'Лабораторная работа №3',
        'description': 'Сдать отчёт в формате PDF (мок).',
        'subject': subj,
        'deadline_at': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'is_done': false,
      },
      {
        'id': 9002,
        'title': 'Контрольная работа',
        'description': 'Темы из лекций 1–4.',
        'subject': 'Математика',
        'deadline_at': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'is_done': true,
      },
    ];
  }

  /// Текущие + зачёт/экзамен для вкладки «Сессия»; даты в пределах последних 14 дней.
  /// Плюс записи «Пропуск» — столько же, сколько [absences] `total_absences`, для списка на экране пропусков.
  static Map<String, dynamic> syncGrades(int userId) {
    // Под форму ответа в логах:
    // {grades:[{semester, records:[{subject, grade, type, date}]}]}
    final sem = '2 сем 2025-2026';
    final now = DateTime.now();
    final d1 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final d2 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 4));
    final d3 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 9));
    return {
      'grades': [
        {
          'semester': sem,
          'records': [
            {
              'subject': 'Электроника и схемотехника',
              'grade': 'Н',
              'type': 'Пропуск',
              'date': _ymd(d3),
            },
            {
              'subject': 'Сети и системы передачи информации',
              'grade': 'Н',
              'type': 'Пропуск',
              'date': _ymd(d2),
            },
            {
              'subject': 'Эксплуатация автоматизированных систем в защищенном исполнении',
              'grade': '5',
              'type': 'Ответ у доски 1 АТ',
              'date': _ymd(d1),
            },
            {
              'subject': 'Техническая защита информации',
              'grade': '5',
              'type': 'Ответ у доски 1 АТ',
              'date': _ymd(d2),
            },
          ],
        },
      ],
    };
  }

  /// Плоский список для `GET /journal/grades/my` (fallback без student_id).
  static List<dynamic> journalGradesFlat(int userId) {
    final root = syncGrades(userId);
    final grades = root['grades'];
    if (grades is! List) return [];
    final out = <dynamic>[];
    for (final e in grades) {
      if (e is! Map) continue;
      final records = e['records'];
      if (records is! List) continue;
      out.addAll(records);
    }
    return out;
  }

  static Map<String, dynamic> mobileHelp() {
    return {
      // Под лог: hotline, email, website_url, faq[{question,answer}]
      'hotline': '+7 (8722) 67-XX-XX',
      'hotline_phone': '+7 (8722) 67-XX-XX',
      'email': 'colledgedsu@dgu.ru',
      'website_url': 'https://college.dgu.ru/',
      'faq': [
        {'question': 'Как восстановить пароль?', 'answer': 'На экране входа нажмите «Забыли пароль» или обратитесь в учебный отдел колледжа.'},
        {'question': 'Где посмотреть расписание?', 'answer': 'В разделе «Расписание» мобильного приложения или на сайте колледжа в личном кабинете студента.'},
        {'question': 'Не приходят уведомления', 'answer': 'Проверьте настройки уведомлений в приложении и разрешения ОС для push.'},
      ],
    };
  }

  static Map<String, dynamic> notificationPreferences() {
    return {
      'push_new_grades': true,
      'push_schedule_change': true,
      'push_assignment_deadlines': true,
      'push_college_news': true,
      'push_college_events': true,
    };
  }

  static Map<String, dynamic> absences(int userId) {
    // Под форму ответа в логах.
    final sem = '2 сем 2025-2026';
    const n = 20;
    final start = DateTime(DateTime.now().year, 2, 1);
    final end = DateTime(DateTime.now().year, 7, 31);
    return {
      'student_id': 23385,
      'status': 'success',
      'semesters': [
        {
          'semester': sem,
          'period': {'start': _ddMmYyyy(start), 'end': _ddMmYyyy(end)},
          'data': {
            'total_absences': n,
            'excused_absences': 0,
            'unexcused_absences': n,
          },
        },
      ],
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Учебный маршрут: часы как объект (см. [LearningRouteView]).
  static List<dynamic> curriculum(int userId) {
    // Под форму ответа в логах: {curriculum:[...]}
    const s2 = 'Сети и системы передачи информации';
    return [
      {
        'subject': 'Биология',
        'semester': '1 семестр',
        'control_form': 'Дифференцированный зачет',
        'hours': {
          'total': 36,
          'theory_lectures': 4,
          'practical': 32,
          'lab': 0,
          'seminar': 0,
          'independent': 0,
          'coursework': 0,
          'consultation': 0,
          'attestation': 4,
          'individual_project': 0,
        },
      },
      {
        'subject': s2,
        'semester': '2 семестр',
        'control_form': 'Не задана',
        'hours': {
          'total': 54,
          'theory_lectures': 14,
          'practical': 40,
          'lab': 0,
          'seminar': 0,
          'independent': 14,
          'coursework': 0,
          'consultation': 0,
          'attestation': 0,
          'individual_project': 0,
        },
      },
    ];
  }

  static List<dynamic> groupList(int userId) {
    return [
      {'name': 'Студент А', 'record_book': 'УБ111'},
      {'name': 'Студент Б', 'record_book': 'УБ222'},
    ];
  }

  static Map<String, dynamic> practices(int userId) {
    return {'items': []};
  }

  /// `POST /api/documents/certificate-order` (MOBILE_SPRAVKI_API.md).
  static Map<String, dynamic> certificateOrderCreate() {
    return {
      'order_id': '550e8400-e29b-41d4-a716-446655440000',
      'status': 'Created',
      'request_id': 1001,
    };
  }

  /// `GET /api/documents/certificate-orders` — при [forStudentId] только заказы этого студента (как на backend).
  static List<Map<String, dynamic>> certificateOrdersHistory({int? forStudentId}) {
    final now = DateTime.now().toUtc().toIso8601String();
    final all = <Map<String, dynamic>>[
      {
        'request_id': 42,
        'order_id': '660e8400-e29b-41d4-a716-446655440001',
        'student_id': MockAccounts.aliId,
        'certificate_type': 'education',
        'delivery_format': 'electronic',
        'present_where': 'В вуз',
        'status': 'pending',
        'created_at': now,
      },
      {
        'request_id': 41,
        'order_id': '770e8400-e29b-41d4-a716-446655440002',
        'student_id': MockAccounts.aliId,
        'certificate_type': 'scholarship',
        'delivery_format': 'paper',
        'present_where': 'По месту работы',
        'status': 'done',
        'created_at': now,
      },
      {
        'request_id': 40,
        'order_id': '880e8400-e29b-41d4-a716-446655440003',
        'student_id': 999,
        'certificate_type': 'education',
        'delivery_format': 'electronic',
        'present_where': 'Другой студент',
        'status': 'done',
        'created_at': now,
      },
    ];
    if (forStudentId == null) return all;
    return [for (final m in all) if (m['student_id'] == forStudentId) m];
  }

  static List<dynamic> oneCCuratorEvents(int userId) {
    return [];
  }

  /// Расписание на один календарный день (`for_date` = yyyy-MM-dd): разные пары по дням недели.
  static Map<String, dynamic> scheduleForDate(String forDateYmd, int userId) {
    // Под форму ответа в логах:
    // {schedule:[{date,day,pair_number,time,subject,room,teacher,week_type,subgroup,semester}], week:null, is_cached:true, schedule_scope:'today', schedule_for_date:'yyyy-MM-dd'}
    final d = DateTime.tryParse(forDateYmd) ?? DateTime.now();
    final dd = _ddMmYyyy(d);
    const days = {
      DateTime.monday: 'Понедельник',
      DateTime.tuesday: 'Вторник',
      DateTime.wednesday: 'Среда',
      DateTime.thursday: 'Четверг',
      DateTime.friday: 'Пятница',
      DateTime.saturday: 'Суббота',
      DateTime.sunday: 'Воскресенье',
    };
    final day = days[d.weekday] ?? 'День';

    if (d.weekday == DateTime.sunday) {
      return {
        'schedule': <dynamic>[],
        'week': null,
        'is_cached': true,
        'schedule_scope': 'today',
        'schedule_for_date': forDateYmd,
      };
    }

    final schedule = <Map<String, dynamic>>[
      {
        'date': dd,
        'day': day,
        'pair_number': 1,
        'time': '14:00 - 15:10',
        'subject': 'Техническая защита информации',
        'room': '215',
        'teacher': 'Багирова София Динмагомедовна',
        'week_type': 'Четная (2 неделя)',
        'subgroup': 0,
        'semester': '2 сем 2025-2026',
      },
      {
        'date': dd,
        'day': day,
        'pair_number': 2,
        'time': '15:20 - 16:30',
        'subject': 'Сети и системы передачи информации',
        'room': '216',
        'teacher': 'Шахбанова Загидат Ибрагимбековна',
        'week_type': 'Четная (2 неделя)',
        'subgroup': 0,
        'semester': '2 сем 2025-2026',
      },
    ];

    return {
      'schedule': schedule,
      'week': null,
      'is_cached': true,
      'schedule_scope': 'today',
      'schedule_for_date': forDateYmd,
    };
  }

  static Map<String, dynamic> scheduleToday(int userId) {
    final now = DateTime.now();
    final ymd = _ymd(now);
    return scheduleForDate(ymd, userId);
  }

  /// Успешные POST без тела.
  static Map<String, dynamic> emptyOk() => {};

  static Map<String, dynamic> parentInviteOk() => {'success': true};

  /// `GET /api/parents/student-data` — родитель видит данные ребёнка (мок — тот же профиль, что у студента 28).
  static Map<String, dynamic> parentsStudentData(int? _) {
    const childId = 28;
    final profile = oneCProfile(childId);
    return {
      'student': {
        'id': childId,
        'full_name': profile['full_name'],
        'full_name_display': 'Ягияев Али Тажутдинович',
        'full_name_genitive': 'Ягияева Али Тажутдиновича',
        'course': profile['course'],
        'direction': profile['direction'],
        'department': profile['department'],
        'student_book_number': profile['student_book_number'],
      },
      'grades': journalGradesFlat(childId),
      'profile_1c': profile,
      'schedule': scheduleToday(childId),
    };
  }

  static Uint8List studentPhotoBytes(int userId) {
    // 1x1 PNG (transparent). Валидная картинка, чтобы Image.file / decoder не падал.
    const b64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/0p7k0kAAAAASUVORK5CYII=';
    return base64Decode(b64);
  }
}
