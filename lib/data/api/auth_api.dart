import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import 'api_client.dart';
import 'api_error_parser.dart';
import 'api_exception.dart';
import '../models/user_model.dart';
import '../services/token_storage.dart';

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

  /// POST /api/auth/login — username (email или номер зачётки), password.
  /// Токен и пользователь приходят в заголовках Authorization, X-User-Data.
  Future<UserModel> login({required String username, required String password}) async {
    try {
      final response = await _api.dio.post<dynamic>(
        ApiConstants.authLoginPath,
        data: <String, String>{'username': username, 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw ApiException(ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка', response.statusCode);
      }

      return _saveAuthFromHeadersOrFetchMe(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/student/verify-1c — проверка студента в 1С (без регистрации).
  Future<StudentVerify1cResult> verifyStudentIn1c({
    required String fullName,
    required String studentBookNumber,
  }) async {
    try {
      final response = await _api.dio.post<dynamic>(
        _studentVerify1cPath,
        data: <String, dynamic>{
          'full_name': fullName.trim(),
          'student_book_number': studentBookNumber.trim(),
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final t = (data['registration_token'] ?? data['registrationToken'] ?? data['token']);
        final s = (t is String) ? t.trim() : (t == null ? '' : '$t').trim();
        return StudentVerify1cResult(registrationToken: s.isEmpty ? null : s);
      }
      return const StudentVerify1cResult(registrationToken: null);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/student/register — регистрация студента (возвращает токен в заголовках).
  Future<UserModel> registerStudent({
    required String fullName,
    required String studentBookNumber,
    required String email,
    required String password,
    String? registrationToken,
  }) async {
    try {
      final response = await _api.dio.post<dynamic>(
        _studentRegisterPath,
        data: <String, dynamic>{
          'full_name': fullName.trim(),
          'student_book_number': studentBookNumber.trim(),
          'email': email.trim(),
          'password': password,
          if (registrationToken != null && registrationToken.trim().isNotEmpty)
            'registration_token': registrationToken.trim(),
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (response.statusCode != 201) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }
      return _saveAuthFromHeadersOrFetchMe(response);
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
