import 'mock_accounts.dart';

/// JSON-ответы мокового API в зависимости от студента ([MockAccounts.variantIndexForUserId]).
abstract final class MockPayloads {
  static Map<String, dynamic> oneCProfile(int userId) {
    final v = MockAccounts.variantIndexForUserId(userId);
    if (v == 1) {
      return {
        'full_name': 'Сидорова Мария Александровна',
        'birth_date': '12.05.2006',
        'group': 'ПКС 2к 1г 2023',
        'department': 'Информационные технологии',
        'direction': 'Программирование',
        'admission_year': '2023',
        'study_form': 'Очная',
        'status': 'Обучается',
        'student_book_number': 'УБ654321',
        'course': 2,
      };
    }
    return {
      'full_name': 'Петров Иван Сергеевич',
      'birth_date': '03.08.2005',
      'group': 'ИСиП 3к 2г 2022',
      'department': 'Информационные технологии',
      'direction': 'Информационные системы',
      'admission_year': '2022',
      'study_form': 'Очная',
      'status': 'Обучается',
      'student_book_number': 'УБ123456',
      'course': 3,
    };
  }

  static Map<String, dynamic> studentTicket(int userId) {
    final p = oneCProfile(userId);
    return {
      'full_name': p['full_name'],
      'student_book_number': p['student_book_number'],
      'birth_date': p['birth_date'],
      'department': p['department'],
      'study_group': p['group'],
      'admission_year': p['admission_year'],
      'study_form': p['study_form'],
      'status': p['status'],
      'course': p['course'],
    };
  }

  static Map<String, dynamic> groupMy(int userId) {
    final v = MockAccounts.variantIndexForUserId(userId);
    if (v == 1) {
      return {'name': 'ПКС 2к 1г 2023', 'code': 'ПКС 2к 1г 2023'};
    }
    return {'name': 'ИСиП 3к 2г 2022', 'code': 'ИСиП 3к 2г 2022'};
  }

  static List<dynamic> newsList(int userId) {
    final tag = userId == MockAccounts.mariaId ? 'Мария' : 'Иван';
    return [
      {
        'id': 1,
        'title': 'Добро пожаловать в приложение (мок)',
        'content': 'Это демонстрационная новость. Режим моковых данных без обращения к серверу.',
        'excerpt': 'Демо-режим',
        'image_url': null,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'title': 'Расписание и задания',
        'content': 'Проверьте вкладки «Расписание» и «Задания» — данные сгенерированы для $tag.',
        'excerpt': null,
        'image_url': null,
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
  }

  static List<dynamic> eventsList(int userId) {
    final start = DateTime.now().add(const Duration(days: 7));
    return [
      {
        'id': 101,
        'title': 'День открытых дверей (мок)',
        'description': 'Приглашаем будущих абитуриентов.',
        'category': 'Колледж',
        'location': 'Главный корпус',
        'start_at': start.toIso8601String(),
        'end_at': start.add(const Duration(hours: 3)).toIso8601String(),
      },
    ];
  }

  static Map<String, dynamic> eventById(int id) {
    return {
      'id': id,
      'title': 'Мероприятие #$id (мок)',
      'description': 'Описание демонстрационного мероприятия.',
      'category': 'Мок',
      'location': 'Колледж ДГУ',
      'start_at': DateTime.now().toIso8601String(),
      'end_at': null,
    };
  }

  static List<dynamic> assignments(int userId) {
    final v = MockAccounts.variantIndexForUserId(userId);
    final subj = v == 1 ? 'Программирование' : 'Базы данных';
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

  static Map<String, dynamic> syncGrades(int userId) {
    final sem = '1 сем 2025-2026';
    final subj = MockAccounts.variantIndexForUserId(userId) == 1 ? 'ООП' : 'СУБД';
    return {
      'grades': [
        {
          'semester': sem,
          'records': [
            {
              'subject_name': subj,
              'grade': '5',
              'grade_type': 'Текущая',
              'teacher_name': 'Преподаватель П.П.',
              'date': '2026-02-10',
              'semester': sem,
            },
            {
              'subject_name': 'Математика',
              'grade': '4',
              'grade_type': 'Текущая',
              'teacher_name': 'Иванов И.И.',
              'date': '2026-02-05',
              'semester': sem,
            },
          ],
        },
      ],
    };
  }

  static Map<String, dynamic> mobileHelp() {
    return {
      'hotline_phone': '+7 (000) 000-00-00',
      'email': 'support@dgu.mock',
      'website_url': 'https://example.com',
      'faq': [
        {'title': 'Что такое мок-режим?', 'answer': 'Данные генерируются локально, запросы к API не отправляются.'},
        {'title': 'Как отключить?', 'answer': 'В main.dart установите useMockBackend = false.'},
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
    final sem = '1 сем 2025-2026';
    final n = MockAccounts.variantIndexForUserId(userId) == 1 ? 2 : 5;
    return {
      'semesters': [
        {
          'semester': sem,
          'data': {'total_absences': n, 'total_hours': 12.0},
        },
      ],
    };
  }

  static List<dynamic> curriculum(int userId) {
    return [
      {'subject': 'Математика', 'hours': 120},
      {'subject': 'Программирование', 'hours': 180},
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

  static Map<String, dynamic> orders(int userId) {
    return {'items': []};
  }

  static List<dynamic> oneCCuratorEvents(int userId) {
    return [];
  }

  /// Расписание на один календарный день (`for_date` = yyyy-MM-dd).
  static Map<String, dynamic> scheduleForDate(String forDateYmd, int userId) {
    final d = DateTime.tryParse(forDateYmd);
    final ddMmYyyy = d == null
        ? forDateYmd
        : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final weekday = d?.weekday ?? DateTime.monday;
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return {'schedule': <dynamic>[]};
    }
    final subj = MockAccounts.variantIndexForUserId(userId) == 1 ? 'ООП' : 'СУБД';
    return {
      'schedule': [
        {
          'pair_number': 1,
          'subject': 'Математика',
          'time': '09:00 - 10:30',
          'teacher': 'Иванов Иван Иванович',
          'auditorium': '101',
          'date': ddMmYyyy,
        },
        {
          'pair_number': 2,
          'subject': subj,
          'time': '10:45 - 12:15',
          'teacher': 'Петрова Анна Сергеевна',
          'auditorium': '204',
          'date': ddMmYyyy,
        },
      ],
    };
  }

  static Map<String, dynamic> scheduleToday(int userId) {
    final now = DateTime.now();
    final ymd =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return scheduleForDate(ymd, userId);
  }

  /// Успешные POST без тела.
  static Map<String, dynamic> emptyOk() => {};
}
