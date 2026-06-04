/// Контакты разработчика мобильного приложения (RuStore, App Store, UI).
abstract final class AppDeveloperInfo {
  static const String fullName = 'Гаджилаев Магомедгаджи';
  static const String email = 'info@gadzhilaev.ru';
  static const String websiteUrl = 'https://mgadzhilaev.ru';

  static const String roleLabel = 'Разработчик приложения';

  static String get websiteHost => Uri.parse(websiteUrl).host;
}
