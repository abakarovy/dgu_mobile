import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../features/schedule/data/schedule_lesson.dart';
import 'api_client.dart';

class ScheduleApi {
  ScheduleApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Календарная дата `yyyy-MM-dd` (локальная).
  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Понедельник календарной недели для [d] (дата без времени).
  static DateTime mondayOfWeekContaining(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  /// GET `/api/1c/schedule?week=числитель&today_only=false` — неделя по типу недели 1С.
  /// Если [week] — дата `yyyy-MM-dd`, трактуем как `for_date` на этот день.
  /// Иначе без [week] — `for_date` на понедельник недели, содержащей [weekStart].
  Future<List<ScheduleLesson>> getWeek({DateTime? weekStart, String? week}) async {
    final w = week?.trim();
    if (w != null && w.isNotEmpty) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(w)) {
        return _fetchScheduleForDate(w);
      }
      return _fetchScheduleWeekFilter(w, todayOnly: false);
    }
    final monday = mondayOfWeekContaining(weekStart ?? DateTime.now());
    return _fetchScheduleForDate(ymd(monday));
  }

  /// Собирает ПН–ВС: для каждого дня `GET /api/1c/schedule?for_date=…`.
  /// Запросы **последовательно**, чтобы не упираться в таймауты и лимиты сервера.
  Future<List<ScheduleLesson>> getWeekForCalendar(DateTime anyInWeek) async {
    final monday = mondayOfWeekContaining(anyInWeek);
    final chunks = <List<ScheduleLesson>>[];
    for (var i = 0; i < 7; i++) {
      try {
        final day = DateTime(monday.year, monday.month, monday.day).add(Duration(days: i));
        final dayYmd = ymd(day);
        chunks.add(await _fetchScheduleForDate(dayYmd));
      } catch (_) {
        chunks.add(<ScheduleLesson>[]);
      }
    }
    return _mergeDedupeLessons(chunks);
  }

  Future<List<ScheduleLesson>> _fetchScheduleForDate(String forDateYmd) async {
    final res = await _api.dio.get<dynamic>(
      '/1c/schedule',
      queryParameters: {'for_date': forDateYmd},
      options: Options(
        validateStatus: (s) => s != null && s < 500,
        receiveTimeout: ApiConstants.scheduleReceiveTimeout,
      ),
    );
    if (res.statusCode != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'Не удалось загрузить расписание',
      );
    }
    final data = res.data;
    var list = _parseSchedule(data);
    if (data is Map<String, dynamic> &&
        _scheduleScopeIsToday(data['schedule_scope'])) {
      final anchor = DateTime.tryParse(forDateYmd);
      if (anchor != null) {
        list = _remapLessonsToAnchorDay(list, anchor);
      }
    }
    return list;
  }

  Future<List<ScheduleLesson>> _fetchScheduleWeekFilter(
    String week,
    {required bool todayOnly}) async {
    final res = await _api.dio.get<dynamic>(
      '/1c/schedule',
      queryParameters: {
        'week': week,
        'today_only': todayOnly,
      },
      options: Options(
        validateStatus: (s) => s != null && s < 500,
        receiveTimeout: ApiConstants.scheduleReceiveTimeout,
      ),
    );
    if (res.statusCode != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'Не удалось загрузить расписание',
      );
    }
    return _parseSchedule(res.data);
  }

  static bool _scheduleScopeIsToday(dynamic scope) {
    if (scope == null) return false;
    return scope.toString().toLowerCase().trim() == 'today';
  }

  /// Бэкенд иногда отдаёт одни и те же пары «на сегодня» при любом `date`, с датой в JSON не того дня.
  /// Привязываем строки к запрошенному календарному дню, чтобы неделя в приложении не была пустой.
  static List<ScheduleLesson> _remapLessonsToAnchorDay(
    List<ScheduleLesson> list,
    DateTime anchorDay,
  ) {
    final date = DateTime(anchorDay.year, anchorDay.month, anchorDay.day);
    final idx = date.weekday - 1;
    return [
      for (final l in list)
        ScheduleLesson(
          weekdayIndex: idx,
          lessonDate: date,
          pairNumber: l.pairNumber,
          subject: l.subject,
          time: l.time,
          teacher: l.teacher,
          auditorium: l.auditorium,
        ),
    ];
  }

  static String _lessonDedupeKey(ScheduleLesson l) {
    final d = l.lessonDate;
    final ds = d == null ? 'x' : ymd(d);
    return '$ds|${l.pairNumber}|${l.subject}|${l.time}|${l.auditorium}|${l.teacher}';
  }

  static List<ScheduleLesson> _mergeDedupeLessons(List<List<ScheduleLesson>> chunks) {
    final seen = <String>{};
    final out = <ScheduleLesson>[];
    for (final list in chunks) {
      for (final l in list) {
        if (seen.add(_lessonDedupeKey(l))) out.add(l);
      }
    }
    out.sort((a, b) {
      final da = a.lessonDate;
      final db = b.lessonDate;
      if (da != null && db != null) {
        final c = da.compareTo(db);
        if (c != 0) return c;
      } else if (da != null) {
        return -1;
      } else if (db != null) {
        return 1;
      }
      final pa = a.pairNumber ?? 9999;
      final pb = b.pairNumber ?? 9999;
      final pc = pa.compareTo(pb);
      if (pc != 0) return pc;
      return a.time.compareTo(b.time);
    });
    return out;
  }

  /// GET `/api/1c/schedule` без query — расписание на сегодня (поведение по умолчанию).
  Future<List<ScheduleLesson>> getToday() async {
    final res = await _api.dio.get<dynamic>(
      '/1c/schedule',
      options: Options(
        validateStatus: (s) => s != null && s < 500,
        receiveTimeout: ApiConstants.scheduleReceiveTimeout,
      ),
    );
    if (res.statusCode != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'Не удалось загрузить расписание',
      );
    }
    final data = res.data;
    var list = _parseSchedule(data);
    if (data is Map<String, dynamic> &&
        _scheduleScopeIsToday(data['schedule_scope'])) {
      final now = DateTime.now();
      final anchor = DateTime(now.year, now.month, now.day);
      list = _remapLessonsToAnchorDay(list, anchor);
    }
    return list;
  }

  List<ScheduleLesson> _parseSchedule(dynamic data) {
    final list = (data is List)
        ? data
        : (data is Map<String, dynamic> && data['schedule'] is List)
            ? (data['schedule'] as List)
            : (data is Map<String, dynamic> && data['items'] is List)
                ? (data['items'] as List)
                : <dynamic>[];

    return list
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(_lessonFromJson)
        .toList();
  }

  static ScheduleLesson _lessonFromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v is String) ? v : (v == null ? '' : '$v');

    final dayShort = str(json['day_short']).toLowerCase().trim();
    final dayFull = str(json['day']).toLowerCase().trim();
    final weekdayIndex = _weekdayIndexFromDay(dayShort, dayFull);

    final subject = str(
      json['subject'] ??
          json['discipline'] ??
          json['name'] ??
          json['title'] ??
          json['lesson_name'],
    ).trim();

    final teacher = str(
      json['teacher'] ??
          json['teacher_name'] ??
          json['lecturer'] ??
          json['professor'],
    ).trim();

    final room = str(
      json['auditorium'] ??
          json['room'] ??
          json['cabinet'] ??
          json['classroom'],
    ).trim();

    final start = str(json['start_time'] ?? json['start'] ?? json['time_start']).trim();
    final end = str(json['end_time'] ?? json['end'] ?? json['time_end']).trim();
    final timeSingle = str(json['time'] ?? json['lesson_time']).trim();
    final time = (start.isNotEmpty && end.isNotEmpty)
        ? '$start—$end'
        : (timeSingle.isNotEmpty ? timeSingle : start);

    final lessonDate = _parseCalendarDate(json['date']);
    int? pairNumber;
    final pn = json['pair_number'];
    if (pn is int) {
      pairNumber = pn;
    } else if (pn != null) {
      pairNumber = int.tryParse(str(pn));
    }

    return ScheduleLesson(
      weekdayIndex: weekdayIndex,
      lessonDate: lessonDate,
      pairNumber: pairNumber,
      subject: subject.isEmpty ? 'Пара' : subject,
      time: time.isEmpty ? '--:--' : time,
      teacher: teacher.isEmpty ? '—' : teacher,
      auditorium: room.isEmpty ? '—' : room,
    );
  }

  /// `14.09.2024` или ISO-строка.
  static DateTime? _parseCalendarDate(dynamic v) {
    final s = (v is String) ? v.trim() : (v == null ? '' : '$v').trim();
    if (s.isEmpty) return null;
    final dot = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');
    final m = dot.firstMatch(s);
    if (m != null) {
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final y = int.tryParse(m.group(3)!);
      if (d != null && mo != null && y != null) {
        return DateTime(y, mo, d);
      }
    }
    final iso = DateTime.tryParse(s);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }
    return null;
  }

  /// Индекс дня ПН=0 … ВС=6. Бэк может отдавать `day_short` (пн/вт/…) или полное `day` («Суббота»).
  static int? _weekdayIndexFromDay(String dayShort, String dayFull) {
    switch (dayShort) {
      case 'пн':
        return 0;
      case 'вт':
        return 1;
      case 'ср':
        return 2;
      case 'чт':
        return 3;
      case 'пт':
        return 4;
      case 'сб':
        return 5;
      case 'вс':
        return 6;
      default:
        break;
    }
    final f = dayFull.trim().toLowerCase();
    if (f.isEmpty) return null;
    if (f.startsWith('понедельник')) return 0;
    if (f.startsWith('вторник')) return 1;
    if (f.startsWith('среда')) return 2;
    if (f.startsWith('четверг')) return 3;
    if (f.startsWith('пятница')) return 4;
    if (f.startsWith('суббота')) return 5;
    if (f.startsWith('воскресенье')) return 6;
    return null;
  }
}

