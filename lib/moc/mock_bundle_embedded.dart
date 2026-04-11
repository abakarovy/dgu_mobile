import 'dart:convert';

/// Встроенные JSON моков (без чтения из `assets/mock/*.txt` — данные доступны сразу после старта).
abstract final class MockBundleEmbedded {
  static const String kAccountsJson = r'''
{
  "aliId": 28,
  "parentId": 29,
  "logins": {
    "student": {
      "email": "ali.yagiyaev@yandex.ru",
      "password": "Test1234"
    },
    "parent": {
      "email": "parent.mock@example.com",
      "password": "Test1234"
    }
  },
  "users": {
    "28": {
      "id": 28,
      "email": "ali.yagiyaev@yandex.ru",
      "full_name": "ЯГИЯЕВ АЛИ ТАЖУТДИНОВИЧ",
      "role": "student",
      "student_book_number": "23385",
      "parent_email": null,
      "course": 3,
      "direction": "10.02.05 Обеспечение информационной безопасности автоматизированных систем",
      "group_id": null,
      "department": "Обеспечение информационной безопасности автоматизированных систем",
      "bio": null,
      "is_active": true,
      "force_password_change": false,
      "created_at": "2026-03-30T15:37:15.799890"
    },
    "29": {
      "id": 29,
      "email": "parent.mock@example.com",
      "full_name": "Родитель — Ягияев Али Тажутдинович",
      "role": "parent",
      "student_book_number": null,
      "parent_email": null,
      "course": null,
      "direction": null,
      "group_id": null,
      "department": null,
      "bio": null,
      "is_active": true,
      "force_password_change": false,
      "created_at": "2026-03-30T15:37:21.003677"
    }
  }
}
''';

  static const String kPayloadsJson = r'''
{
  "oneCProfileBase": {
    "is_cached": true,
    "student_id": 23385,
    "last_name": "ЯГИЯЕВ",
    "first_name": "АЛИ",
    "middle_name": "ТАЖУТДИНОВИЧ",
    "birthday": "10.09.2007",
    "direction": "10.02.05 Обеспечение информационной безопасности автоматизированных систем",
    "group": "ОИБАС 3к 1г 2023",
    "department": "Обеспечение информационной безопасности автоматизированных систем",
    "education_form": "Очная форма обучения",
    "admission_year": "2023",
    "course": 3,
    "curator": "Шахбанова Марият Ибрагимбековна",
    "social_role": "",
    "status": "Обучается",
    "funding_type": "Бюджетное финансирование",
    "student_book_number": "23385",
    "study_form": "Очная форма обучения",
    "full_name": "ЯГИЯЕВ АЛИ ТАЖУТДИНОВИЧ"
  },
  "syncGradesSemester": "2 сем 2025-2026",
  "gradeRecords": [
    {"daysAgo": 9, "subject": "Электроника и схемотехника", "grade": "Н", "type": "Пропуск"},
    {"daysAgo": 4, "subject": "Сети и системы передачи информации", "grade": "Н", "type": "Пропуск"},
    {"daysAgo": 1, "subject": "Сети и системы передачи информации", "grade": "5", "type": "Ответ у доски 1 АТ", "teacher_name": "Петров Пётр Сергеевич"},
    {"daysAgo": 4, "subject": "Сети и системы передачи информации", "grade": "4", "type": "Ответ у доски 2 АТ", "teacher_name": "Петров Пётр Сергеевич"},
    {"daysAgo": 9, "subject": "Сети и системы передачи информации", "grade": "5", "type": "Контрольная работа", "teacher_name": "Петров Пётр Сергеевич"},
    {"daysAgo": 12, "subject": "Сети и системы передачи информации", "grade": "5", "type": "Практическое занятие", "teacher_name": "Петров Пётр Сергеевич"},
    {"daysAgo": 1, "subject": "Эксплуатация автоматизированных систем в защищенном исполнении", "grade": "5", "type": "Ответ у доски 1 АТ", "teacher_name": "Козлов Денис Олегович"},
    {"daysAgo": 4, "subject": "Эксплуатация автоматизированных систем в защищенном исполнении", "grade": "4", "type": "Опрос терминов", "teacher_name": "Козлов Денис Олегович"},
    {"daysAgo": 4, "subject": "Техническая защита информации", "grade": "5", "type": "Ответ у доски 1 АТ", "teacher_name": "Сидорова Анна Викторовна"},
    {"daysAgo": 9, "subject": "Техническая защита информации", "grade": "5", "type": "Юрайт", "teacher_name": "Сидорова Анна Викторовна"},
    {"daysAgo": 0, "subject": "Сети и системы передачи информации", "grade": "5", "type": "Экзамен", "teacher_name": "Петров Пётр Сергеевич"},
    {"daysAgo": 1, "subject": "Сети и системы передачи информации", "grade": "5", "type": "Дифференцированный зачёт", "teacher_name": "Петров Пётр Сергеевич"},
    {"daysAgo": 1, "subject": "Техническая защита информации", "grade": "зачёт", "type": "Зачёт", "teacher_name": "Сидорова Анна Викторовна"},
    {"daysAgo": 4, "subject": "Эксплуатация автоматизированных систем в защищенном исполнении", "grade": "4", "type": "Курсовая работа", "teacher_name": "Козлов Денис Олегович"}
  ],
  "mobileHelp": {
    "hotline": "+7 (8722) 67-XX-XX",
    "hotline_phone": "+7 (8722) 67-XX-XX",
    "email": "colledgedsu@dgu.ru",
    "website_url": "https://college.dgu.ru/",
    "faq": [
      {"question": "Как восстановить пароль?", "answer": "На экране входа нажмите «Забыли пароль» или обратитесь в учебный отдел колледжа."},
      {"question": "Где посмотреть расписание?", "answer": "В разделе «Расписание» мобильного приложения или на сайте колледжа в личном кабинете студента."},
      {"question": "Не приходят уведомления", "answer": "Проверьте настройки уведомлений в приложении и разрешения ОС для push."}
    ]
  },
  "notificationPreferences": {
    "push_new_grades": true,
    "push_schedule_change": true,
    "push_assignment_deadlines": true,
    "push_college_news": true,
    "push_college_events": true
  },
  "news_items": [
    {
      "title": "День открытых дверей (мок)",
      "content": "Приходите смотреть (мок).",
      "excerpt": "День открытых дверей",
      "image_url": "assets/images/img1.png",
      "id": 11,
      "author_id": 7,
      "createdAtDaysAgo": 1
    },
    {
      "title": "Студвесна (мок)",
      "content": "Приходите смотреть, Али.",
      "excerpt": "Студвесна в колледже ДГУ",
      "image_url": "assets/images/img2.png",
      "id": 10,
      "author_id": 7,
      "createdAtDaysAgo": 2
    }
  ],
  "events_items": [
    {
      "id": 1,
      "title": "Мероприятие (мок)",
      "description": "Описание мероприятия (мок).",
      "image_url": null,
      "location": "Колледж ДГУ",
      "startsAtDaysFromNow": 7,
      "ends_at": null,
      "is_published": true
    }
  ],
  "assignments_items": [
    {
      "id": 9001,
      "title": "Лабораторная работа №3",
      "description": "Сдать отчёт в формате PDF (мок).",
      "subject": "Сети и системы передачи информации",
      "deadlineDaysFromNow": 5,
      "createdDaysAgo": 2,
      "is_done": false
    },
    {
      "id": 9002,
      "title": "Контрольная работа",
      "description": "Темы из лекций 1–4.",
      "subject": "Математика",
      "deadlineDaysFromNow": 14,
      "createdDaysAgo": 1,
      "is_done": true
    }
  ],
  "curriculum": [
    {
      "subject": "Биология",
      "semester": "1 семестр",
      "control_form": "Дифференцированный зачет",
      "hours": {
        "total": 36,
        "theory_lectures": 4,
        "practical": 32,
        "lab": 0,
        "seminar": 0,
        "independent": 0,
        "coursework": 0,
        "consultation": 0,
        "attestation": 4,
        "individual_project": 0
      }
    },
    {
      "subject": "Сети и системы передачи информации",
      "semester": "2 семестр",
      "control_form": "Не задана",
      "hours": {
        "total": 54,
        "theory_lectures": 14,
        "practical": 40,
        "lab": 0,
        "seminar": 0,
        "independent": 14,
        "coursework": 0,
        "consultation": 0,
        "attestation": 0,
        "individual_project": 0
      }
    }
  ],
  "group_list": [
    {"name": "Студент А", "record_book": "УБ111"},
    {"name": "Студент Б", "record_book": "УБ222"}
  ],
  "absences": {
    "semester": "2 сем 2025-2026",
    "periodStartMonth": 2,
    "periodStartDay": 1,
    "periodEndMonth": 7,
    "periodEndDay": 31,
    "total_absences": 20,
    "excused_absences": 0,
    "unexcused_absences": 20,
    "total_hours": 120
  },
  "certificate_order_create": {
    "order_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "Created",
    "request_id": 1001
  },
  "certificate_orders": [
    {
      "request_id": 42,
      "order_id": "660e8400-e29b-41d4-a716-446655440001",
      "student_id": 28,
      "certificate_type": "education",
      "delivery_format": "electronic",
      "present_where": "В вуз",
      "status": "pending"
    },
    {
      "request_id": 41,
      "order_id": "770e8400-e29b-41d4-a716-446655440002",
      "student_id": 28,
      "certificate_type": "scholarship",
      "delivery_format": "paper",
      "present_where": "По месту работы",
      "status": "done"
    },
    {
      "request_id": 40,
      "order_id": "880e8400-e29b-41d4-a716-446655440003",
      "student_id": 999,
      "certificate_type": "education",
      "delivery_format": "electronic",
      "present_where": "Другой студент",
      "status": "done"
    }
  ],
  "practices": {"items": []},
  "schedule_pair_templates": [
    {
      "pair_number": 1,
      "time": "09:00 - 10:10",
      "subject": "Электроника и схемотехника",
      "room": "312",
      "teacher": "Иванов Иван Иванович",
      "week_type": "Четная (2 неделя)",
      "subgroup": 0,
      "semester": "2 сем 2025-2026"
    },
    {
      "pair_number": 2,
      "time": "10:20 - 11:30",
      "subject": "Техническая защита информации",
      "room": "215",
      "teacher": "Багирова София Динмагомедовна",
      "week_type": "Четная (2 неделя)",
      "subgroup": 0,
      "semester": "2 сем 2025-2026"
    },
    {
      "pair_number": 3,
      "time": "12:10 - 13:20",
      "subject": "Сети и системы передачи информации",
      "room": "216",
      "teacher": "Шахбанова Загидат Ибрагимбековна",
      "week_type": "Четная (2 неделя)",
      "subgroup": 0,
      "semester": "2 сем 2025-2026"
    },
    {
      "pair_number": 4,
      "time": "14:00 - 15:10",
      "subject": "Эксплуатация автоматизированных систем в защищённом исполнении",
      "room": "218",
      "teacher": "Козлов Денис Олегович",
      "week_type": "Четная (2 неделя)",
      "subgroup": 0,
      "semester": "2 сем 2025-2026"
    }
  ]
}
''';

  static Map<String, dynamic>? _accounts;
  static Map<String, dynamic>? _payloads;

  static Map<String, dynamic> get accounts =>
      _accounts ??= jsonDecode(kAccountsJson) as Map<String, dynamic>;

  static Map<String, dynamic> get payloads =>
      _payloads ??= jsonDecode(kPayloadsJson) as Map<String, dynamic>;
}
