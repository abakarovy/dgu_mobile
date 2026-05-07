import 'dart:convert';
import 'dart:typed_data';

import 'mock_accounts.dart';
import 'mock_data_loader.dart';
import 'mock_scholarship_catalog_document.dart';
import 'mock_student_portal_public.dart';

/// JSON-ответы мокового API (встроены в [MockBundleEmbedded] / [MockDataLoader.payloads]).
abstract final class MockPayloads {
  static Map<String, dynamic> get _p => MockDataLoader.payloads;

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _ddMmYyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _ymdDaysAgo(int daysAgo) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
    return _ymd(base);
  }

  static Map<String, dynamic> oneCProfile(int userId) {
    final base = Map<String, dynamic>.from(_p['oneCProfileBase'] as Map);
    base['grades'] = syncGrades(userId)['grades'];
    return base;
  }

  static Map<String, dynamic> studentTicket(int userId) {
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

  static Map<String, dynamic> groupMy(int userId) => {};

  static List<dynamic> newsList(int userId) {
    final now = DateTime.now();
    final raw = List<Map<String, dynamic>>.from(
      (_p['news_items'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final out = <Map<String, dynamic>>[];
    for (final m in raw) {
      final copy = Map<String, dynamic>.from(m);
      final days = copy.remove('createdAtDaysAgo') as int;
      copy['created_at'] = now.subtract(Duration(days: days)).toIso8601String();
      copy['updated_at'] = null;
      copy['is_published'] = true;
      out.add(copy);
    }
    return out;
  }

  static List<dynamic> eventsList(int userId) {
    final now = DateTime.now();
    final raw = List<Map<String, dynamic>>.from(
      (_p['events_items'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final out = <Map<String, dynamic>>[];
    for (final m in raw) {
      final copy = Map<String, dynamic>.from(m);
      final add = copy.remove('startsAtDaysFromNow') as int;
      copy['starts_at'] = now.add(Duration(days: add)).toIso8601String();
      copy['created_at'] = now.toIso8601String();
      out.add(copy);
    }
    return out;
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
    final now = DateTime.now();
    final raw = List<Map<String, dynamic>>.from(
      (_p['assignments_items'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final out = <Map<String, dynamic>>[];
    for (final m in raw) {
      final copy = Map<String, dynamic>.from(m);
      final deadline = copy.remove('deadlineDaysFromNow') as int;
      final createdAgo = copy.remove('createdDaysAgo') as int;
      copy['deadline_at'] = now.add(Duration(days: deadline)).toIso8601String();
      copy['created_at'] = now.subtract(Duration(days: createdAgo)).toIso8601String();
      out.add(copy);
    }
    return out;
  }

  static Map<String, dynamic> syncGrades(int userId) {
    final sem = _p['syncGradesSemester'] as String;
    final raw = List<Map<String, dynamic>>.from(
      (_p['gradeRecords'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final records = <Map<String, dynamic>>[];
    for (final r in raw) {
      final copy = Map<String, dynamic>.from(r);
      final daysAgo = copy.remove('daysAgo') as int;
      copy['date'] = _ymdDaysAgo(daysAgo);
      records.add(copy);
    }
    return {
      'grades': [
        {'semester': sem, 'records': records},
      ],
    };
  }

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

  static Map<String, dynamic> mobileHelp() =>
      Map<String, dynamic>.from(_p['mobileHelp'] as Map);

  static Map<String, dynamic> notificationPreferences() =>
      Map<String, dynamic>.from(_p['notificationPreferences'] as Map);

  static Map<String, dynamic> _fallbackAbsencesConfig() => {
        'semester': '2 сем 2025-2026',
        'periodStartMonth': 2,
        'periodStartDay': 1,
        'periodEndMonth': 7,
        'periodEndDay': 31,
        'total_absences': 20,
        'excused_absences': 0,
        'unexcused_absences': 20,
        'total_hours': 120,
      };

  static Map<String, dynamic> absences(int userId) {
    Map<String, dynamic> a;
    try {
      a = Map<String, dynamic>.from(_p['absences'] as Map);
    } catch (_) {
      a = _fallbackAbsencesConfig();
    }
    final sem = a['semester'] as String;
    final y = DateTime.now().year;
    final start = DateTime(y, a['periodStartMonth'] as int, a['periodStartDay'] as int);
    final end = DateTime(y, a['periodEndMonth'] as int, a['periodEndDay'] as int);
    final totalHours = (a['total_hours'] is num)
        ? (a['total_hours'] as num).toDouble()
        : double.tryParse('${a['total_hours'] ?? ''}');
    return {
      'student_id': userId,
      'status': 'success',
      // Подпись в профиле, если семестр из оценок не совпал с `semesters[]`.
      'total_hours': totalHours,
      'semesters': [
        {
          'semester': sem,
          'period': {'start': _ddMmYyyy(start), 'end': _ddMmYyyy(end)},
          'data': {
            'total_absences': a['total_absences'],
            'excused_absences': a['excused_absences'],
            'unexcused_absences': a['unexcused_absences'],
            'total_hours': totalHours,
          },
        },
      ],
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static List<dynamic> curriculum(int userId) =>
      List<dynamic>.from(_p['curriculum'] as List);

  static List<dynamic> groupList(int userId) =>
      List<dynamic>.from(_p['group_list'] as List);

  static Map<String, dynamic> practices(int userId) =>
      Map<String, dynamic>.from(_p['practices'] as Map);

  static Map<String, dynamic> certificateOrderCreate() =>
      Map<String, dynamic>.from(_p['certificate_order_create'] as Map);

  static List<Map<String, dynamic>> certificateOrdersHistory({int? forStudentId}) {
    final now = DateTime.now().toUtc().toIso8601String();
    final raw = List<Map<String, dynamic>>.from(
      (_p['certificate_orders'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final all = <Map<String, dynamic>>[];
    for (final m in raw) {
      final copy = Map<String, dynamic>.from(m)..['created_at'] = now;
      all.add(copy);
    }
    if (forStudentId == null) return all;
    return [for (final m in all) if (m['student_id'] == forStudentId) m];
  }

  static List<dynamic> oneCCuratorEvents(int userId) => [];

  static Map<String, dynamic> _fallbackScheduleRow() => {
        'pair_number': 1,
        'time': '09:00 - 10:10',
        'subject': 'Пара (мок)',
        'room': '101',
        'teacher': 'Преподаватель (мок)',
        'week_type': '',
        'subgroup': 0,
        'semester': '2 сем 2025-2026',
      };

  static List<Map<String, dynamic>> _scheduleTemplates() {
    try {
      final raw = _p['schedule_pair_templates'];
      if (raw is! List || raw.isEmpty) {
        return [_fallbackScheduleRow()];
      }
      final out = <Map<String, dynamic>>[];
      for (final e in raw) {
        if (e is Map) out.add(Map<String, dynamic>.from(e));
      }
      return out.isEmpty ? [_fallbackScheduleRow()] : out;
    } catch (_) {
      return [_fallbackScheduleRow()];
    }
  }

  static Map<String, dynamic> scheduleForDate(String forDateYmd, int userId) {
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
    const dayShortRu = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

    final templates = _scheduleTemplates();
    final n = templates.length;
    final schedule = <Map<String, dynamic>>[];
    // Воскресенье — выходной, пар в моке нет.
    if (n > 0 && d.weekday != DateTime.sunday) {
      // Сдвиг предметов по дню недели; время и номер пары — всегда из слота i (1-я пара с утра и т.д.).
      final shift = (d.weekday - DateTime.monday) % n;
      for (var i = 0; i < n; i++) {
        final slot = Map<String, dynamic>.from(templates[i]);
        final content = templates[(i + shift) % n];
        final row = Map<String, dynamic>.from(content);
        row['pair_number'] = slot['pair_number'] ?? (i + 1);
        row['time'] = slot['time'];
        row['date'] = dd;
        row['day'] = day;
        row['day_short'] = dayShortRu[d.weekday - 1];
        schedule.add(row);
      }
    }

    return {
      'schedule': schedule,
      'week': null,
      'is_cached': true,
      // Не `today`: пары уже с датой запрошенного дня (в т.ч. апрель 2026 в моке).
      'schedule_scope': 'date',
      'schedule_for_date': forDateYmd,
    };
  }

  static Map<String, dynamic> scheduleToday(int userId) {
    final now = DateTime.now();
    final ymd = _ymd(now);
    return scheduleForDate(ymd, userId);
  }

  static Map<String, dynamic> emptyOk() => {};

  static Map<String, dynamic> parentInviteOk() => {'success': true};

  static Map<String, dynamic> parentsStudentData(int? _) {
    final childId = MockAccounts.aliId;
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
    final loaded = MockDataLoader.mockAvatarPngBytes;
    if (loaded != null && loaded.isNotEmpty) return loaded;
    const b64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/0p7k0kAAAAASUVORK5CYII=';
    return base64Decode(b64);
  }

  // --- Студенческие модули (см. MOBILE_STUDENT_MODULES_RU) ---

  static List<dynamic> lmsList() => [];

  static Map<String, dynamic> lmsCredential(int id) => {
        'id': id,
        'service_name': id == 2 ? 'profspo' : 'urait',
        'login': 'demo_student',
      };

  static List<dynamic> departmentAnnouncements() => [
        {
          'id': 9001,
          'title': 'График приёма документов (мок)',
          'body':
              'Уважаемые студенты! В мае приём справок ведётся по средам 14:00–17:00. Это демонстрационное объявление в режиме мок-бэкенда.',
          'created_at': '2026-05-01T09:00:00+03:00',
          'group_code': 'DEMO-GROUP',
        },
      ];

  static Map<String, dynamic> portfolioMyComplete() => {
        'storage': 'site_only',
        'self_uploads': <dynamic>[
          {
            'id': 1,
            'file_url': '/uploads/mock/portfolio_certificate.png',
            'file_name': 'Сертификат_курса.png',
            'description': null,
            'status': 'approved',
            'points': 10,
            'created_at': '2026-05-01T12:00:00+03:00',
            'kind': 'student_upload',
            'section': 'certificate',
          },
          {
            'id': 2,
            'file_url': '/uploads/mock/portfolio_diploma.jpg',
            'file_name': 'Грамота_олимпиады.jpg',
            'description': 'Региональный этап',
            'status': 'approved',
            'points': 5,
            'created_at': '2026-05-02T14:30:00+03:00',
            'kind': 'student_upload',
            'section': 'diploma',
          },
          {
            'id': 3,
            'file_url': '/uploads/mock/portfolio_pending.pdf',
            'file_name': 'Справка.pdf',
            'description': null,
            'status': 'pending',
            'points': null,
            'created_at': '2026-05-06T10:00:00+03:00',
            'kind': 'student_upload',
            'section': 'general',
          },
          {
            'id': 4,
            'file_url': '/uploads/mock/portfolio_reject.docx',
            'file_name': 'Черновик.docx',
            'description': null,
            'status': 'rejected',
            'points': null,
            'created_at': '2026-04-20T09:00:00+03:00',
            'kind': 'student_upload',
            'section': 'course',
          },
        ],
        'official_final_works': <dynamic>[
          {
            'id': 101,
            'subject_name': 'Техническая защита информации',
            'work_type': 'coursework',
            'original_filename': 'Курсовая_ТЗИ.pdf',
            'file_url': '/uploads/mock/official_coursework.pdf',
            'upload_deadline_at': '2026-06-15',
            'is_past_deadline': false,
          },
          {
            'id': 102,
            'subject_name': 'Сети и системы передачи информации',
            'work_type': 'diploma',
            'original_filename': null,
            'file_url': '/uploads/mock/official_diploma.pdf',
            'upload_deadline_at': '2026-05-01',
            'is_past_deadline': true,
          },
        ],
      };

  static List<dynamic> portfolioMyList() {
    final su = portfolioMyComplete()['self_uploads'];
    return su is List ? List<dynamic>.from(su) : [];
  }

  /// Сумма `points` по одобренным самозагрузкам из [portfolioMyComplete].
  static Map<String, dynamic> portfolioRating() => {'total_points': 15};

  static Map<String, dynamic> portfolioShareStatus() => {
        'active': true,
        'token': 'RXviwDvcr3SRn7Tqu0S6qaw_8hN4VTERmIHc2chONYE',
        'public_url':
            'http://localhost:3000/portfolio/p/RXviwDvcr3SRn7Tqu0S6qaw_8hN4VTERmIHc2chONYE',
      };

  static Map<String, dynamic> studentPortalPublic() => Map<String, dynamic>.from(
        mockStudentPortalPublicSnapshot(),
      );

  static Map<String, dynamic> scholarshipCatalogDocument() => mockScholarshipCatalogDocument();

  /// Сводка стипендиального рейтинга (семестр в query: `fall` / `spring`).
  static Map<String, dynamic> scholarshipSummary({required String semester}) {
    if (semester == 'fall') {
      return {
        'academic_year': '2025-2026',
        'semester': 'fall',
        'category_totals': {
          'study': 22.0,
          'science': 0.0,
          'society': 0.0,
          'culture': 0.0,
          'sport': 0.0,
        },
        'total_approved': 22.0,
        'entries': <dynamic>[
          {
            'id': 3,
            'academic_year': '2025-2026',
            'semester': 'fall',
            'criterion_id': '1.2.1',
            'criterion_label': 'Международный уровень',
            'category_id': 'study',
            'option_key': null,
            'authors_count': 1,
            'notes': null,
            'file_url': '/uploads/mock/scholarship_mock.pdf',
            'file_name': 'Документ_критерия.pdf',
            'suggested_points': 20,
            'status': 'approved',
            'approved_points': 22,
            'reviewer_comment': null,
            'created_at': '2026-05-06T09:24:04+03:00',
            'reviewed_at': '2026-05-06T09:24:36+03:00',
          },
          {
            'id': 4,
            'academic_year': '2025-2026',
            'semester': 'fall',
            'criterion_id': '1.3.2',
            'criterion_label': 'Всероссийский уровень',
            'category_id': 'study',
            'option_key': 'prize',
            'authors_count': 2,
            'notes': 'Соавтор: Иванов И.И.',
            'file_url': '/uploads/mock/scholarship_scan.png',
            'file_name': 'Диплом_призёр.png',
            'suggested_points': 14,
            'status': 'pending',
            'approved_points': null,
            'reviewer_comment': null,
            'created_at': '2026-05-07T11:00:00+03:00',
            'reviewed_at': null,
          },
        ],
      };
    }

    return {
      'academic_year': '2025-2026',
      'semester': 'spring',
      'category_totals': {
        'study': 11.0,
        'science': 5.0,
        'society': 0.0,
        'culture': 0.0,
        'sport': 0.0,
      },
      'total_approved': 16.0,
      'entries': <dynamic>[
        {
          'id': 5,
          'academic_year': '2025-2026',
          'semester': 'spring',
          'criterion_id': '2.1.1',
          'criterion_label': 'Публикация (пример)',
          'category_id': 'science',
          'option_key': null,
          'authors_count': 1,
          'notes': null,
          'file_url': '/uploads/mock/article.pdf',
          'file_name': 'Статья_VAK.pdf',
          'suggested_points': 5,
          'status': 'approved',
          'approved_points': 5,
          'reviewer_comment': null,
          'created_at': '2026-05-05T10:00:00+03:00',
          'reviewed_at': '2026-05-05T12:00:00+03:00',
        },
        {
          'id': 6,
          'academic_year': '2025-2026',
          'semester': 'spring',
          'criterion_id': '1.2.3',
          'criterion_label': 'Региональный уровень',
          'category_id': 'study',
          'option_key': null,
          'authors_count': 1,
          'notes': 'Неверный скан',
          'file_url': '/uploads/mock/bad_scan.pdf',
          'file_name': 'Скан.pdf',
          'suggested_points': 10,
          'status': 'rejected',
          'approved_points': null,
          'reviewer_comment': 'Нечитаемый документ',
          'created_at': '2026-05-04T09:00:00+03:00',
          'reviewed_at': '2026-05-04T15:00:00+03:00',
        },
      ],
    };
  }
}
