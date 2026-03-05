import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import 'api_client.dart';
import '../models/user_model.dart';
import '../services/token_storage.dart';

/// Ошибка ответа API (detail от бэкенда).
class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

/// Auth API: логин (email или № з/к), получение текущего пользователя.
class AuthApi {
  AuthApi({required ApiClient apiClient, required TokenStorage tokenStorage})
      : _api = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  /// POST /api/auth/login — username (email или номер зачётки), password.
  /// Токен и пользователь приходят в заголовках Authorization, X-User-Data.
  Future<UserModel> login({required String username, required String password}) async {
    final response = await _api.dio.post<dynamic>(
      ApiConstants.authLoginPath,
      data: <String, String>{'username': username, 'password': password},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (response.statusCode != 200) {
      final detail = _extractDetail(response);
      throw ApiException(detail ?? 'Ошибка входа', response.statusCode);
    }

    final token = response.headers.value('Authorization')?.replaceFirst('Bearer ', '').trim() ??
        response.headers.value('X-Auth-Token');
    if (token == null || token.isEmpty) {
      throw ApiException('Сервер не вернул токен');
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

    final me = await getMe();
    final json = jsonEncode(me.toJson());
    await _tokenStorage.setUserDataJson(json);
    return me;
  }

  /// GET /api/auth/me — текущий пользователь (Bearer).
  Future<UserModel> getMe() async {
    final response = await _api.dio.get<Map<String, dynamic>>(ApiConstants.authMePath);
    if (response.statusCode != 200 || response.data == null) {
      final detail = _extractDetail(response);
      throw ApiException(detail ?? 'Не удалось загрузить профиль', response.statusCode);
    }
    return UserModel.fromJson(response.data!);
  }

  static String? _extractDetail(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) return first['msg'] as String;
      }
    }
    return null;
  }
}
