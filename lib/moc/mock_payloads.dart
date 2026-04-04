import 'mock_accounts.dart';

/// JSON-ответы мокового API в зависимости от студента ([MockAccounts.variantIndexForUserId]).
abstract final class MockPayloads {
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Строки «Пропуск…» для журнала — экран «Пропуски» → «Текущие» ([AbsencesPage._journalAbsencesInRange]).
  static List<Map<String, dynamic>> _mockAbsenceJournalRows(String semester, int count) {
    if (count <= 0) return [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const offsets = [1, 2, 3, 5, 7, 10, 11, 12, 13];
    const subjects = [
      'Математика',
      'СУБД',
      'Физкультура',
      'История',
      'Английский язык',
      'ООП',
      'Информатика',
    ];
    const types = [
      'Пропуск по уважительной причине',
      'Пропуск (болезнь)',
      'пропуск по семейным обстоятельствам',
    ];
    return [
      for (var i = 0; i < count; i++)
        {
          'subject_name': subjects[i % subjects.length],
          'grade': 'Н',
          'grade_type': types[i % types.length],
          'teacher_name': 'Преподаватель Т.Т.',
          'date': _ymd(today.subtract(Duration(days: offsets[i % offsets.length]))),
          'semester': semester,
        },
    ];
  }

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
      'full_name': 'Ягияев Али Тажутдинович',
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
        'image_url': 'assets/images/2.png',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'title': 'Расписание и задания',
        'content': 'Проверьте вкладки «Расписание» и «Задания» — данные сгенерированы для $tag.',
        'excerpt': null,
        'image_url': 'assets/images/3.png',
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

  /// Текущие + зачёт/экзамен для вкладки «Сессия»; даты в пределах последних 14 дней.
  /// Плюс записи «Пропуск» — столько же, сколько [absences] `total_absences`, для списка на экране пропусков.
  static Map<String, dynamic> syncGrades(int userId) {
    final sem = '1 сем 2025-2026';
    final subj = MockAccounts.variantIndexForUserId(userId) == 1 ? 'ООП' : 'СУБД';
    final absenceCount = MockAccounts.variantIndexForUserId(userId) == 1 ? 2 : 5;
    final now = DateTime.now();
    final d1 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final d2 = now.subtract(const Duration(days: 4));
    final d3 = now.subtract(const Duration(days: 9));
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
              'date': _ymd(d1),
              'semester': sem,
            },
            {
              'subject_name': 'Математика',
              'grade': '4',
              'grade_type': 'Текущая',
              'teacher_name': 'Иванов И.И.',
              'date': _ymd(d2),
              'semester': sem,
            },
            {
              'subject_name': 'История',
              'grade': '5',
              'grade_type': 'Ответ у доски',
              'teacher_name': 'Смирнов С.С.',
              'date': _ymd(d3),
              'semester': sem,
            },
            {
              'subject_name': 'Математика',
              'grade': '4',
              'grade_type': 'Зачёт',
              'teacher_name': 'Иванов И.И.',
              'date': _ymd(d1),
              'semester': sem,
            },
            {
              'subject_name': subj,
              'grade': '5',
              'grade_type': 'Экзамен',
              'teacher_name': 'Петрова А.С.',
              'date': _ymd(d2),
              'semester': sem,
            },
            {
              'subject_name': 'Английский язык',
              'grade': 'зачтено',
              'grade_type': '1 АТ',
              'teacher_name': 'Ли О.В.',
              'date': _ymd(d3),
              'semester': sem,
            },
            ..._mockAbsenceJournalRows(sem, absenceCount),
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

  /// Учебный маршрут: часы как объект (см. [LearningRouteView]).
  static List<dynamic> curriculum(int userId) {
    final v = MockAccounts.variantIndexForUserId(userId);
    final s2 = v == 1 ? 'ООП' : 'СУБД';
    return [
      {
        'subject': 'Математика',
        'discipline': 'Математика',
        'control_form': 'Экзамен',
        'hours': {
          'total': 120,
          'theory_lectures': 48,
          'lab': 0,
          'practical': 48,
          'independent': 24,
        },
      },
      {
        'subject': s2,
        'discipline': s2,
        'control_form': 'Зачёт с оценкой',
        'hours': {
          'total': 180,
          'theory_lectures': 60,
          'lab': 72,
          'practical': 36,
          'independent': 12,
        },
      },
      {
        'subject': 'Информатика',
        'control_form': 'Дифференцированный зачёт',
        'hours': {
          'total': 64,
          'theory_lectures': 32,
          'lab': 32,
          'practical': 0,
          'independent': 0,
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

  static Map<String, dynamic> orders(int userId) {
    return {'items': []};
  }

  static List<dynamic> oneCCuratorEvents(int userId) {
    return [];
  }

  static const List<String> _dayShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  /// Расписание на один календарный день (`for_date` = yyyy-MM-dd): разные пары по дням недели.
  static Map<String, dynamic> scheduleForDate(String forDateYmd, int userId) {
    final d = DateTime.tryParse(forDateYmd);
    final ddMmYyyy = d == null
        ? forDateYmd
        : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final weekday = d?.weekday ?? DateTime.monday;
    // Только воскресенье без пар (как выходной); суббота — учебный день с парами.
    if (weekday == DateTime.sunday) {
      return {'schedule': <dynamic>[]};
    }
    final dayIdx = weekday - 1;
    final dayShort = _dayShort[dayIdx.clamp(0, 6)];
    final spec = MockAccounts.variantIndexForUserId(userId) == 1 ? 'ООП' : 'СУБД';

    final pair1Subjects = [
      'Математика',
      'Физика',
      'История',
      'Английский язык',
      'Информатика',
      'Английский язык',
    ];
    final pair2Subjects = [
      spec,
      'Компьютерные сети',
      'Физкультура',
      'Экономика',
      'Право',
      'Компьютерные сети',
    ];
    final t1 = [
      '09:00 - 10:30',
      '09:00 - 10:30',
      '10:45 - 12:15',
      '09:00 - 10:30',
      '08:30 - 10:00',
      '08:30 - 10:00',
    ];
    final t2 = [
      '10:45 - 12:15',
      '10:45 - 12:15',
      '12:30 - 14:00',
      '10:45 - 12:15',
      '10:15 - 11:45',
      '10:30 - 12:00',
    ];

    final i = dayIdx.clamp(0, pair1Subjects.length - 1);
    return {
      'schedule': [
        {
          'pair_number': 1,
          'day_short': dayShort,
          'subject': pair1Subjects[i],
          'time': t1[i],
          'teacher': 'Иванов Иван Иванович',
          'auditorium': '${101 + i}',
          'date': ddMmYyyy,
        },
        {
          'pair_number': 2,
          'day_short': dayShort,
          'subject': pair2Subjects[i],
          'time': t2[i],
          'teacher': 'Петрова Анна Сергеевна',
          'auditorium': '${204 + i}',
          'date': ddMmYyyy,
        },
      ],
    };
  }

  static Map<String, dynamic> scheduleToday(int userId) {
    final now = DateTime.now();
    final ymd = _ymd(now);
    return scheduleForDate(ymd, userId);
  }

  /// Успешные POST без тела.
  static Map<String, dynamic> emptyOk() => {};
}
