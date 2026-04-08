/// Общие константы приложения.
abstract final class AppConstants {
  static const String appName = 'DGU Mobile';
  static const String appVersion = '0.1.0';

  /// Ключ SharedPreferences для пути к аватарке профиля.
  static const String profileAvatarPathKey = 'profile_avatar_path';
  static const String profileAvatarFileName = 'avatar.jpg';

  /// Фото студента из 1С: кэшированный файл, полученный через `GET /api/1c/student-photo`.
  /// Используется, если пользователь не выбрал собственную аватарку.
  static const String profile1cPhotoPathKey = 'profile_1c_photo_path';
  static const String profile1cPhotoFileName = 'avatar_1c.jpg';
}
