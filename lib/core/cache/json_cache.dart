import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Простой JSON-кэш: сохраняет строку + время обновления.
class JsonCache {
  JsonCache(this._prefs);

  final SharedPreferences _prefs;

  static Future<JsonCache> create() async =>
      JsonCache(await SharedPreferences.getInstance());

  String _dataKey(String key) => 'cache:$key:data';
  String _tsKey(String key) => 'cache:$key:ts';

  Future<void> setJson(String key, Object value) async {
    final jsonStr = jsonEncode(value);
    await _prefs.setString(_dataKey(key), jsonStr);
    await _prefs.setInt(_tsKey(key), DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getJsonMap(String key) {
    final s = _prefs.getString(_dataKey(key));
    if (s == null || s.isEmpty) return null;
    try {
      final v = jsonDecode(s);
      // `jsonDecode` даёт `Map`, не всегда строго `Map<String, dynamic>` — иначе кэш «пустой».
      if (v is Map) {
        return Map<String, dynamic>.from(v);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<dynamic>? getJsonList(String key) {
    final s = _prefs.getString(_dataKey(key));
    if (s == null || s.isEmpty) return null;
    try {
      final v = jsonDecode(s);
      return v is List ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// Удаляет все записи кэша (`cache:*`), не трогая токен и прочие ключи SharedPreferences.
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith('cache:')) {
        await _prefs.remove(key);
      }
    }
  }
}

