import 'package:shared_preferences/shared_preferences.dart';

/// Хранение JWT и данных пользователя (ключи SharedPreferences).
class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyToken = 'auth_token';
  static const String _keyUserData = 'auth_user_data';

  static Future<TokenStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  Future<String?> getToken() async => _prefs.getString(_keyToken);

  Future<void> setToken(String token) => _prefs.setString(_keyToken, token);

  Future<String?> getUserDataJson() => Future.value(_prefs.getString(_keyUserData));

  Future<void> setUserDataJson(String json) => _prefs.setString(_keyUserData, json);

  Future<void> clear() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUserData);
  }
}
