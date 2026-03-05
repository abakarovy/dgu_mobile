import 'dart:convert';

import '../../../../data/api/auth_api.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Реализация AuthRepository через College DGU API и TokenStorage.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthApi authApi, required TokenStorage tokenStorage})
      : _authApi = authApi,
        _tokenStorage = tokenStorage;

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  @override
  Future<UserEntity> login({required String username, required String password}) async {
    final user = await _authApi.login(username: username.trim(), password: password);
    return user.toEntity();
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clear();
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
