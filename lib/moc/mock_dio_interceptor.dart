import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import 'mock_accounts.dart';
import 'mock_mode.dart';
import 'mock_payloads.dart';
import 'mock_session.dart';

/// Перехватывает все запросы [Dio] и отвечает локальными JSON (режим [useMockBackend]).
class MockDioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!useMockBackend) {
      return handler.next(options);
    }

    try {
      final r = _mockResponse(options);
      if (r != null) {
        return handler.resolve(r);
      }
    } catch (e, st) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: st,
          type: DioExceptionType.unknown,
        ),
      );
    }

    return handler.reject(
      DioException(
        requestOptions: options,
        message: 'Мок: неизвестный запрос ${options.method} ${options.uri}',
        type: DioExceptionType.unknown,
      ),
    );
  }

  static Response<dynamic>? _mockResponse(RequestOptions o) {
    final path = o.uri.path;
    final method = o.method.toUpperCase();

    if (method == 'POST' && _pathEnds(path, ApiConstants.authLoginPath)) {
      return _postLogin(o);
    }
    if (method == 'POST' && _pathEnds(path, '/auth/staff/login')) {
      return _jsonResponse(o, 401, {'detail': 'Мок: вход сотрудника не поддержан'});
    }
    if (method == 'POST' && _pathEnds(path, '/auth/student/verify-1c')) {
      return _jsonResponse(o, 200, {'registration_token': 'mock-registration-token'});
    }
    if (method == 'POST' && _pathEnds(path, '/auth/student/register')) {
      return _postRegisterStudent(o);
    }

    final uid = _userId(o) ?? MockAccounts.aliId;

    if (method == 'GET' && _pathEnds(path, ApiConstants.authMePath)) {
      return _getMe(o);
    }

    if (method == 'GET' && _pathEnds(path, '/news')) {
      return _jsonResponse(o, 200, MockPayloads.newsList(uid));
    }
    if (method == 'GET' && _pathEnds(path, '/groups/my')) {
      // В логах бэкенд возвращает список (часто `[]`).
      return _jsonResponse(o, 200, <dynamic>[]);
    }
    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCMyProfilePath)) {
      return _jsonResponse(o, 200, MockPayloads.oneCProfile(uid));
    }
    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCSyncGradesPath)) {
      return _jsonResponse(o, 200, MockPayloads.syncGrades(uid));
    }
    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCFinalGradesPath)) {
      return _jsonResponse(o, 200, MockPayloads.syncGrades(uid));
    }
    if (method == 'GET' && _pathEnds(path, '/journal/grades/my')) {
      return _jsonResponse(o, 200, MockPayloads.journalGradesFlat(uid));
    }

    if (method == 'GET' && _pathEnds(path, '/1c/schedule')) {
      final q = o.uri.queryParameters;
      if (q.containsKey('for_date')) {
        return _jsonResponse(o, 200, MockPayloads.scheduleForDate(q['for_date']!, uid));
      }
      if (q.containsKey('week')) {
        return _jsonResponse(o, 200, MockPayloads.scheduleToday(uid));
      }
      return _jsonResponse(o, 200, MockPayloads.scheduleToday(uid));
    }

    if (method == 'GET' && _pathEnds(path, '/mobile/assignments/my')) {
      return _jsonResponse(o, 200, MockPayloads.assignments(uid));
    }
    if (method == 'POST' && _pathEnds(path, '/mobile/assignments')) {
      return _jsonResponse(o, 201, {
        'id': 9999,
        'title': 'Новое задание (мок)',
        'is_done': false,
      });
    }

    if (method == 'GET' && _pathEnds(path, '/mobile/student-ticket')) {
      return _jsonResponse(o, 200, MockPayloads.studentTicket(uid));
    }
    if (method == 'GET' && _pathEnds(path, '/mobile/help')) {
      return _jsonResponse(o, 200, MockPayloads.mobileHelp());
    }
    if (method == 'GET' && _pathEnds(path, '/mobile/notification-preferences')) {
      return _jsonResponse(o, 200, MockPayloads.notificationPreferences());
    }
    if (method == 'PATCH' && _pathEnds(path, '/mobile/notification-preferences')) {
      final body = _asMap(o.data);
      final base = MockPayloads.notificationPreferences();
      base.addAll(body.map((k, v) => MapEntry(k.toString(), v)));
      return _jsonResponse(o, 200, base);
    }

    if (method == 'GET' && _pathEnds(path, '/mobile/events')) {
      return _jsonResponse(o, 200, MockPayloads.eventsList(uid));
    }
    if (method == 'GET' && path.contains('/mobile/events/')) {
      final id = int.tryParse(path.split('/mobile/events/').last.split('/').first);
      if (id != null) {
        return _jsonResponse(o, 200, MockPayloads.eventById(id));
      }
    }

    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCCurriculumPath)) {
      return _jsonResponse(o, 200, {'curriculum': MockPayloads.curriculum(uid)});
    }
    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCAbsencesPath)) {
      return _jsonResponse(o, 200, MockPayloads.absences(uid));
    }
    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCGroupListPath)) {
      return _jsonResponse(o, 200, MockPayloads.groupList(uid));
    }
    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCPracticesPath)) {
      return _jsonResponse(o, 200, MockPayloads.practices(uid));
    }
    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCOrdersPath)) {
      return _jsonResponse(o, 200, MockPayloads.orders(uid));
    }
    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCCuratorEventsPath)) {
      return _jsonResponse(o, 200, MockPayloads.oneCCuratorEvents(uid));
    }

    if (method == 'POST' && _pathEnds(path, '/push/device')) {
      return _jsonResponse(o, 201, MockPayloads.emptyOk());
    }
    if (method == 'DELETE' && _pathEnds(path, '/push/device')) {
      return Response(requestOptions: o, statusCode: 204, data: null);
    }

    if (method == 'POST' && _pathEnds(path, '/auth/parent/invite')) {
      return _jsonResponse(o, 200, MockPayloads.parentInviteOk());
    }
    if (method == 'POST' && _pathEnds(path, '/auth/email-change/request')) {
      return _jsonResponse(o, 200, MockPayloads.emptyOk());
    }
    if (method == 'POST' && _pathEnds(path, '/auth/email-change/confirm')) {
      return _jsonResponse(o, 200, MockPayloads.emptyOk());
    }
    if (method == 'POST' && _pathEnds(path, '/auth/password-reset/request')) {
      return _jsonResponse(o, 200, MockPayloads.emptyOk());
    }
    if (method == 'POST' && _pathEnds(path, '/auth/password-reset/request-self')) {
      return _jsonResponse(o, 200, MockPayloads.emptyOk());
    }
    if (method == 'POST' && _pathEnds(path, '/auth/password-reset/complete')) {
      return _jsonResponse(o, 200, MockPayloads.emptyOk());
    }

    if (method == 'GET' && _pathEnds(path, ApiConstants.healthPath)) {
      return _jsonResponse(o, 200, {'status': 'ok', 'mock': true});
    }

    if (method == 'GET' && _pathEnds(path, ApiConstants.oneCStudentPhotoPath)) {
      // Binary payload: return image bytes directly (Dio `ResponseType.bytes` compatible).
      return Response(
        requestOptions: o,
        statusCode: 200,
        headers: Headers.fromMap({
          'content-type': ['image/png'],
        }),
        data: MockPayloads.studentPhotoBytes(uid),
      );
    }

    return null;
  }

  static Response<dynamic> _postLogin(RequestOptions o) {
    final form = _parseForm(o.data);
    final username = form['username'] ?? form['email'] ?? '';
    final password = form['password'] ?? '';
    final match = MockAccounts.tryLogin(username, password);
    if (match == null) {
      return Response(
        requestOptions: o,
        statusCode: 401,
        data: {'detail': 'Неверный логин или пароль (мок)'},
      );
    }
    MockSession.lastUserId = match.userId;
    return Response(
      requestOptions: o,
      statusCode: 200,
      headers: Headers.fromMap({
        'Authorization': [MockAccounts.bearerForUserId(match.userId)],
        'X-User-Data': [MockAccounts.xUserDataHeaderFor(match.userId)],
      }),
      data: null,
    );
  }

  static Response<dynamic> _postRegisterStudent(RequestOptions o) {
    final m = _asMap(o.data);
    final email = '${m['email'] ?? ''}'.trim();
    final fullName = '${m['full_name'] ?? 'Студент Моковый'}'.trim();
    final user = Map<String, dynamic>.from(MockAccounts.userJsonById(MockAccounts.aliId));
    user['email'] = email.isNotEmpty ? email : user['email'];
    user['full_name'] = fullName;
    final id = user['id'] as int;
    return Response(
      requestOptions: o,
      statusCode: 201,
      headers: Headers.fromMap({
        'Authorization': [MockAccounts.bearerForUserId(id)],
        'X-User-Data': [base64Encode(utf8.encode(jsonEncode(user)))],
      }),
      data: null,
    );
  }

  static Response<dynamic> _getMe(RequestOptions o) {
    final h = o.headers['Authorization'] ?? o.headers['authorization'];
    String? bearer;
    if (h is List && h.isNotEmpty) {
      bearer = h.first.toString();
    } else if (h is String) {
      bearer = h;
    }
    final json = MockAccounts.userJsonFromBearer(bearer);
    if (json == null) {
      return Response(requestOptions: o, statusCode: 401, data: {'detail': 'Unauthorized (мок)'});
    }
    return Response(requestOptions: o, statusCode: 200, data: json);
  }

  static Response<dynamic> _jsonResponse(
    RequestOptions o,
    int code,
    Object? data,
  ) {
    return Response(requestOptions: o, statusCode: code, data: data);
  }

  static bool _pathEnds(String path, String suffix) {
    final p = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final s = suffix.startsWith('/') ? suffix : '/$suffix';
    return p.endsWith(s) || path.endsWith('$s/');
  }

  static Map<String, String> _parseForm(dynamic data) {
    if (data is Map) {
      return data.map((k, v) => MapEntry('$k'.toLowerCase(), '$v'));
    }
    if (data is String) {
      final out = <String, String>{};
      for (final part in data.split('&')) {
        final i = part.indexOf('=');
        if (i <= 0) continue;
        final key = Uri.decodeQueryComponent(part.substring(0, i));
        final val = Uri.decodeQueryComponent(part.substring(i + 1));
        out[key.toLowerCase()] = val;
      }
      return out;
    }
    return {};
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static int? _userId(RequestOptions o) {
    final h = o.headers['Authorization'] ?? o.headers['authorization'];
    String? bearer;
    if (h is List && h.isNotEmpty) {
      bearer = h.first.toString();
    } else if (h is String) {
      bearer = h;
    }
    final fromBearer = MockAccounts.userJsonFromBearer(bearer);
    if (fromBearer != null) return fromBearer['id'] as int?;
    final sid = o.uri.queryParameters['student_id'];
    if (sid != null) return int.tryParse(sid);
    return null;
  }
}
