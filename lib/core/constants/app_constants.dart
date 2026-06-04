import 'app_release_info.dart';

/// Общие константы приложения.
abstract final class AppConstants {
  static const String appName = 'DGU Mobile';
  static const String appVersion = AppReleaseInfo.version;

  /// Ключ SharedPreferences для пути к аватарке профиля.
  static const String profileAvatarPathKey = 'profile_avatar_path';
  static const String profileAvatarFileName = 'avatar.jpg';

  /// Фото студента из 1С: кэш на диске, имя файла — [Profile1cPhotoCache.diskCacheFileName].
  /// См. legacy [profile1cPhotoFileName] — при выходе из аккаунта удаляется вместе с `avatar_1c_*.jpg`.
  static const String profile1cPhotoPathKey = 'profile_1c_photo_path';

  /// Устаревшее имя одного файла на всех пользователей (Windows мог показывать чужое фото).
  static const String profile1cPhotoFileName = 'avatar_1c.jpg';

  /// Время (epoch ms), до которого кнопка "Сбросить" заблокирована (anti-spam).
  static const String passwordResetCooldownUntilMsKey = 'password_reset_cooldown_until_ms';

  /// Локальные черновики заказов справок ([CertificateOrderPage]).
  static const String certificateOrdersPrefsKey = 'profile:certificate_orders_v3';

  /// Последний JSON ответа `GET /api/students/me/parent-status` (восстановление бейджа после перезапуска).
  static const String profileLastParentStatusJsonKey = 'profile:last_parent_status_json';
}
