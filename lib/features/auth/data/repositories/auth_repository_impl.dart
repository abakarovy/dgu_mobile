import 'dart:convert';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/cache/json_cache.dart';
import '../../../../core/push/push_registrar.dart';
import '../../../../core/realtime/realtime_ws_client.dart';
import '../../../../data/api/auth_api.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Реализация AuthRepository через College DGU API и TokenStorage.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApi authApi,
    required TokenStorage tokenStorage,
    required JsonCache jsonCache,
  })  : _authApi = authApi,
        _tokenStorage = tokenStorage,
        _jsonCache = jsonCache;

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;
  final JsonCache _jsonCache;

  @override
  Future<UserEntity> login({required String username, required String password}) async {
    final user = await _authApi.login(username: username.trim(), password: password);
    PushRegistrar.instance.ensureRegistered();
    RealtimeWsClient.instance.connectIfPossible();
    AuthSession.bump();
    return user.toEntity();
  }

  @override
  Future<String?> verifyStudentIn1c({
    required String fullName,
    required String studentBookNumber,
  }) async {
    final r = await _authApi.verifyStudentIn1c(
      fullName: fullName.trim(),
      studentBookNumber: studentBookNumber.trim(),
    );
    return r.registrationToken;
  }

  @override
  Future<UserEntity> registerStudent({
    required String fullName,
    required String studentBookNumber,
    required String email,
    required String password,
    String? registrationToken,
  }) async {
    final user = await _authApi.registerStudent(
      fullName: fullName.trim(),
      studentBookNumber: studentBookNumber.trim(),
      email: email.trim(),
      password: password,
      registrationToken: registrationToken,
    );
    PushRegistrar.instance.ensureRegistered();
    RealtimeWsClient.instance.connectIfPossible();
    AuthSession.bump();
    return user.toEntity();
  }

  @override
  Future<void> logout() async {
    await PushRegistrar.instance.unregisterCurrentDevice();
    await RealtimeWsClient.instance.disconnect();
    await _tokenStorage.clear();
    await _jsonCache.clearAll();
    AuthSession.bump();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return null;
    final jsonStr = await _tokenStorage.getUserDataJson();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final user = UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
        return user.toEntity();
      } catch (_) {
        // ignore
      }
    }
    try {
      final user = await _authApi.getMe();
      await _tokenStorage.setUserDataJson(jsonEncode(user.toJson()));
      return user.toEntity();
    } catch (_) {
      return null;
    }
  }
}
