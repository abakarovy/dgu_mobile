import 'package:shared_preferences/shared_preferences.dart';

/// Порядок четырёх боковых вкладок (ветки shell: 0 Профиль, 1 Оценки, 3 Новости, 4 Мероприятия). «Главная» (2) фиксирована по центру.
abstract final class NavBarOrderPrefs {
  static const String _key = 'nav_bar_movable_order_v1';

  static const List<int> defaultOrder = [0, 1, 3, 4];

  static Future<List<int>> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null || s.isEmpty) return List<int>.from(defaultOrder);
    try {
      final parts = s.split(',').map(int.parse).toList();
      if (!_isPermutation(parts)) return List<int>.from(defaultOrder);
      return parts;
    } catch (_) {
      return List<int>.from(defaultOrder);
    }
  }

  static Future<void> save(List<int> order) async {
    if (!_isPermutation(order)) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, order.join(','));
  }

  static bool _isPermutation(List<int> parts) {
    if (parts.length != 4) return false;
    const want = {0, 1, 3, 4};
    return parts.toSet().length == 4 && parts.every(want.contains);
  }
}
