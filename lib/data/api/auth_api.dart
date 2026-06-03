import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import 'api_client.dart';
import 'api_error_parser.dart';
import 'api_exception.dart';
import 'auth_api_outcomes.dart';
import '../models/user_model.dart';
import '../services/token_storage.dart';

int? _readOtpSeconds(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v'.trim());
}

class StudentVerify1cResult {
  const StudentVerify1cResult({this.registrationToken});
  final String? registrationToken;
}

/// Auth API: логин (email или № з/к), получение текущего пользователя.
class AuthApi {
  AuthApi({required ApiClient apiClient, required TokenStorage tokenStorage})
      : _api = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  static const String _studentVerify1cPath = '/auth/student/verify-1c';
  static const String _studentRegistrationSupportPath =
      '/auth/student/support/registration-report';
  static const String _studentRegisterPath = '/auth/student/register';
  static const String _staffLoginPath = '/auth/staff/login';

  Future<UserModel> _saveAuthFromHeadersOrFetchMe(Response<dynamic> response) async {
    final token = response.headers
            .value('Authorization')
            ?.replaceFirst('Bearer ', '')
            .trim() ??
        response.headers.value('X-Auth-Token');
    if (token == null || token.isEmpty) {
      // Без токена сообщение от бэка показать нельзя.
      throw ApiException('Ошибка', response.statusCode);
    }
    await _tokenStorage.setToken(token);

    final userDataB64 = response.headers.value('X-User-Data');
    if (userDataB64 != null && userDataB64.isNotEmpty) {
      try {
        final json = utf8.decode(base64.decode(userDataB64));
        final user = UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
        await _tokenStorage.setUserDataJson(json);
        return user;
      } catch (_) {
        // fallback: запросить /auth/me
      }
    }

    try {
      final me = await getMe();
      final json = jsonEncode(me.toJson());
      await _tokenStorage.setUserDataJson(json);
      return me;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/login — form: username, password; при OTP — второй запрос с `otp_code`.
  /// Ответ `200` + `requires_otp: true` — без JWT; иначе токен в заголовках (§5.3).
  Future<AuthApiLoginOutcome> login({
    required String username,
    required String password,
    String? otpCode,
  }) async {
    try {
      final response = await _api.dio.post<dynamic>(
        ApiConstants.authLoginPath,
        data: <String, String>{
          'username': username.trim(),
          'password': password,
          if (otpCode != null && otpCode.trim().isNotEmpty) 'otp_code': otpCode.trim(),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final code = response.statusCode ?? 0;
      if (code == 429) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ??
              'Слишком частые запросы. Подождите немного.',
          429,
        );
      }
      if (code == 401 || code == 403) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка входа',
          code,
        );
      }
      if (code != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          code,
        );
      }

      final body = response.data;
      if (body is Map) {
        final map = Map<String, dynamic>.from(body);
        if (map['requires_otp'] == true) {
          return AuthApiLoginOtpRequired(
            message: (map['message'] ?? 'Введите код из письма.').toString(),
            emailMasked: map['email_masked']?.toString(),
            resendAfterSeconds: _readOtpSeconds(map['resend_after_seconds']) ?? 30,
          );
        }
      }

      return AuthApiLoginSuccess(await _saveAuthFromHeadersOrFetchMe(response));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/student/verify-1c — проверка студента в 1С (без регистрации).
  /// [lastName], [firstName], [patronymic] — для письма в YouGile при 404 (с бэкенда).
  Future<StudentVerify1cResult> verifyStudentIn1c({
    required String fullName,
    required String studentBookNumber,
    String? lastName,
    String? firstName,
    String? patronymic,
  }) async {
    try {
      final data = <String, dynamic>{
        'full_name': fullName.trim(),
        'student_book_number': studentBookNumber.trim(),
      };
      final ln = lastName?.trim();
      final fn = firstName?.trim();
      final pn = patronymic?.trim();
      if (ln != null && ln.isNotEmpty) data['last_name'] = ln;
      if (fn != null && fn.isNotEmpty) data['first_name'] = fn;
      if (pn != null && pn.isNotEmpty) data['patronymic'] = pn;

      final response = await _api.dio.post<dynamic>(
        _studentVerify1cPath,
        data: data,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }

      final payload = response.data;
      if (payload is Map) {
        final map = Map<String, dynamic>.from(payload);
        final t = (map['registration_token'] ?? map['registrationToken'] ?? map['token']);
        final s = (t is String) ? t.trim() : (t == null ? '' : '$t').trim();
        return StudentVerify1cResult(registrationToken: s.isEmpty ? null : s);
      }
      return const StudentVerify1cResult(registrationToken: null);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/auth/student/support/registration-report` — опционально (не дублировать стандартный 404).
  /// Без JWT. Успех: 200 + `{ ok, message }`.
  Future<String> postStudentRegistrationSupportReport({
    required String source,
    required String message,
    required String fullName,
    required String studentBookNumber,
    String? lastName,
    String? firstName,
    String? patronymic,
    String? registrationEmail,
    String? errorCode,
  }) async {
    try {
      final body = <String, dynamic>{
        'source': source.trim(),
        'message': message.trim(),
        'full_name': fullName.trim(),
        'student_book_number': studentBookNumber.trim(),
        'error_code': (errorCode != null && errorCode.trim().isNotEmpty)
            ? errorCode.trim()
            : 'NOT_FOUND',
      };
      final ln = lastName?.trim();
      final fn = firstName?.trim();
      final pn = patronymic?.trim();
      if (ln != null && ln.isNotEmpty) body['last_name'] = ln;
      if (fn != null && fn.isNotEmpty) body['first_name'] = fn;
      if (pn != null && pn.isNotEmpty) body['patronymic'] = pn;
      final re = registrationEmail?.trim();
      if (re != null && re.isNotEmpty) body['registration_email'] = re;

      final response = await _api.dio.post<dynamic>(
        _studentRegistrationSupportPath,
        data: body,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final code = response.statusCode ?? 0;
      if (code != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          code,
        );
      }
      final data = response.data;
      if (data is Map) {
        final m = data['message'];
        if (m is String && m.trim().isNotEmpty) return m.trim();
      }
      return 'Сообщение передано в поддержку.';
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/student/register — при OTP первый ответ `200` + `requires_otp`, второй `201` + JWT.
  Future<AuthApiRegisterOutcome> registerStudent({
    required String fullName,
    required String studentBookNumber,
    required String email,
    required String password,
    String? registrationToken,
    String? otpCode,
  }) async {
    try {
      final response = await _api.dio.post<dynamic>(
        _studentRegisterPath,
        data: <String, dynamic>{
          'full_name': fullName.trim(),
          'student_book_number': studentBookNumber.trim(),
          'email': email.trim(),
          'password': password,
          'registration_client': ApiConstants.registrationClientMobile,
          if (registrationToken != null && registrationToken.trim().isNotEmpty)
            'registration_token': registrationToken.trim(),
          if (otpCode != null && otpCode.trim().isNotEmpty) 'otp_code': otpCode.trim(),
        },
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          headers: {
            ApiConstants.registrationClientHeader:
                ApiConstants.registrationClientMobile,
          },
        ),
      );

      final code = response.statusCode ?? 0;
      if (code == 429) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ??
              'Слишком частые запросы. Подождите немного.',
          429,
        );
      }
      if (code == 401 || code == 403) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          code,
        );
      }
      if (code == 200) {
        final body = response.data;
        if (body is Map) {
          final map = Map<String, dynamic>.from(body);
          if (map['requires_otp'] == true) {
            return AuthApiRegisterOtpRequired(
              message: (map['message'] ?? 'Введите код из письма.').toString(),
              emailMasked: map['email_masked']?.toString(),
              resendAfterSeconds: _readOtpSeconds(map['resend_after_seconds']) ?? 30,
            );
          }
        }
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка регистрации',
          200,
        );
      }
      if (code == 201) {
        return AuthApiRegisterSuccess(await _saveAuthFromHeadersOrFetchMe(response));
      }
      throw ApiException(
        ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
        code,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/staff/login — вход сотрудника/админа (JSON username/password).
  Future<UserModel> loginStaff({required String username, required String password}) async {
    try {
      final response = await _api.dio.post<dynamic>(
        _staffLoginPath,
        data: <String, dynamic>{'username': username.trim(), 'password': password},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (response.statusCode != 200) {
        throw ApiException(ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка', response.statusCode);
      }
      return _saveAuthFromHeadersOrFetchMe(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/auth/me — текущий пользователь (Bearer).
  Future<UserModel> getMe() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(ApiConstants.authMePath);
      if (response.statusCode != 200 || response.data == null) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
