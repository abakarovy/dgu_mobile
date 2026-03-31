import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

class AccountApi {
  AccountApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// POST /api/auth/parent/invite
  ///
  /// Приглашение родителя студентом (привязка email родителя к аккаунту).
  Future<void> inviteParent({required String parentEmail}) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/auth/parent/invite',
        data: {'parent_email': parentEmail.trim()},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/email-change/request
  Future<void> requestEmailChange({required String newEmail}) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/auth/email-change/request',
        data: {'new_email': newEmail.trim()},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/email-change/confirm
  Future<void> confirmEmailChange({required String newEmail, required String code}) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/auth/email-change/confirm',
        data: {'new_email': newEmail.trim(), 'code': code.trim()},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/password-reset/request (public)
  Future<void> requestPasswordReset({required String email}) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/auth/password-reset/request',
        data: {'email': email.trim()},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/password-reset/request-self (auth)
  Future<void> requestPasswordResetSelf() async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/auth/password-reset/request-self',
        data: const <String, dynamic>{},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/auth/password-reset/complete
  Future<void> completePasswordReset({
    required String token,
    required String password,
    required String passwordRepeat,
  }) async {
    try {
      final res = await _api.dio.post<dynamic>(
        '/auth/password-reset/complete',
        data: {
          'token': token.trim(),
          'password': password,
          'password_repeat': passwordRepeat,
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode != 200) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

