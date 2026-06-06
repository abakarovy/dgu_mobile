import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/applicant_model.dart';
import '../models/staff_capabilities_model.dart';
import '../models/user_model.dart';
import '../services/token_storage.dart';
import 'api_client.dart';
import 'api_error_parser.dart';
import 'api_exception.dart';

/// API персонала (`/api/v1/...`), см. docs/MOBILE_STAFF_PERSONNEL.md.
class StaffApi {
  StaffApi({required ApiClient apiClient, required TokenStorage tokenStorage})
      : _api = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  static const String capabilitiesPath = '/v1/staff/capabilities';
  static const String loginPath = '/v1/auth/staff';
  static const String profilePath = '/v1/user/profile';
  static const String avatarPath = '/v1/user/avatar';
  static const String applicantsPath = '/v1/admin/applicants';
  static const String paymentCutoffPath = '/v1/admin/payment-cutoff';
  static const String setPaymentCutoffPath = '/v1/admin/set-payment-cutoff';

  static Options get _json200 => Options(validateStatus: (s) => s != null && s < 500);

  /// GET /api/v1/staff/capabilities — меню модулей (не хардкодить по роли).
  Future<StaffCapabilitiesModel> getCapabilities() async {
    try {
      final response = await _api.dio.get<dynamic>(capabilitiesPath, options: _json200);
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Некорректный ответ сервера', response.statusCode);
      }
      return StaffCapabilitiesModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/v1/auth/staff — токен в теле ответа.
  Future<UserModel> loginStaff({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post<dynamic>(
        loginPath,
        data: <String, dynamic>{
          'email': email.trim(),
          'password': password,
        },
        options: _json200,
      );
      final code = response.statusCode ?? 0;
      if (code == 401 || code == 403) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Неверный e-mail или пароль',
          code,
        );
      }
      if (code != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка входа',
          code,
        );
      }
      final body = response.data;
      if (body is! Map) {
        throw ApiException('Некорректный ответ сервера', code);
      }
      final map = Map<String, dynamic>.from(body);
      final token = (map['token'] ?? '').toString().trim();
      if (token.isEmpty) {
        throw ApiException('Токен не получен', code);
      }
      await _tokenStorage.setToken(token);
      final userRaw = map['user'];
      if (userRaw is! Map) {
        throw ApiException('Данные пользователя не получены', code);
      }
      final user = UserModel.fromJson(Map<String, dynamic>.from(userRaw));
      await _tokenStorage.setUserDataJson(jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/v1/user/profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _api.dio.get<dynamic>(profilePath, options: _json200);
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Некорректный ответ сервера', response.statusCode);
      }
      return UserModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/v1/user/avatar — multipart, поле `avatar`.
  Future<String> uploadAvatar(String filePath) async {
    try {
      final response = await _api.dio.post<dynamic>(
        avatarPath,
        data: FormData.fromMap({
          'avatar': await MultipartFile.fromFile(filePath),
        }),
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          contentType: 'multipart/form-data',
        ),
      );
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Не удалось загрузить фото',
          response.statusCode,
        );
      }
      final data = response.data;
      if (data is Map) {
        return (data['avatar_url'] ?? '').toString();
      }
      throw ApiException('Некорректный ответ сервера', response.statusCode);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/v1/admin/applicants
  Future<ApplicantsPageResult> getApplicants({
    String? search,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _api.dio.get<dynamic>(
        applicantsPath,
        queryParameters: <String, dynamic>{
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'skip': skip,
          'limit': limit.clamp(1, 500),
        },
        options: _json200,
      );
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Некорректный ответ сервера', response.statusCode);
      }
      return ApplicantsPageResult.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/v1/admin/applicants/{id}
  Future<ApplicantDetail> getApplicant(int id) async {
    try {
      final response = await _api.dio.get<dynamic>(
        '$applicantsPath/$id',
        options: _json200,
      );
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Некорректный ответ сервера', response.statusCode);
      }
      return ApplicantDetail.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/v1/admin/payment-cutoff
  Future<PaymentCutoffResult> getPaymentCutoff() async {
    try {
      final response = await _api.dio.get<dynamic>(paymentCutoffPath, options: _json200);
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Некорректный ответ сервера', response.statusCode);
      }
      return PaymentCutoffResult.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/v1/admin/set-payment-cutoff
  Future<SetPaymentCutoffResult> setPaymentCutoff(double cutoffScore) async {
    try {
      final response = await _api.dio.post<dynamic>(
        setPaymentCutoffPath,
        data: <String, dynamic>{'cutoff_score': cutoffScore},
        options: _json200,
      );
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ?? 'Ошибка',
          response.statusCode,
        );
      }
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Некорректный ответ сервера', response.statusCode);
      }
      return SetPaymentCutoffResult.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static String resolveAvatarUrl(String? avatarUrl) =>
      ApiConstants.resolvePublicFileUrl(avatarUrl ?? '');

  static const String webHandoffPath = '/v1/auth/web-handoff';

  /// POST /api/v1/auth/web-handoff — одноразовая ссылка для входа на сайт.
  Future<String> createWebHandoffUrl({
    required String target,
    int? resourceId,
  }) async {
    try {
      final body = <String, dynamic>{'target': target};
      if (resourceId != null) body['resource_id'] = resourceId;

      final response = await _api.dio.post<dynamic>(
        webHandoffPath,
        data: body,
        options: _json200,
      );
      if (response.statusCode != 200) {
        throw ApiException(
          ApiErrorParser.fromResponseData(response.data) ??
              'Не удалось открыть редактор на сайте',
          response.statusCode,
        );
      }
      final data = response.data;
      if (data is! Map) {
        throw ApiException('Некорректный ответ сервера', response.statusCode);
      }
      final url = (data['url'] ?? '').toString().trim();
      if (url.isEmpty) {
        throw ApiException('Ссылка не получена', response.statusCode);
      }
      return url;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
