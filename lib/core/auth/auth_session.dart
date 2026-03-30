/// Увеличивается при смене аккаунта, чтобы вкладки IndexedStack пересоздали State и не держали старые Future/данные.
abstract final class AuthSession {
  static int _epoch = 0;
  static int get epoch => _epoch;
  static void bump() => _epoch++;
}
