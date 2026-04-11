import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Удаляет данные пользователя вне JSON-кэша и токена: пути к фото, черновики справок, cooldown сброса пароля.
Future<void> wipeUserLocalPreferencesAndAvatarFiles() async {
  final prefs = await SharedPreferences.getInstance();
  final avatarPath = prefs.getString(AppConstants.profileAvatarPathKey);
  final oneCPath = prefs.getString(AppConstants.profile1cPhotoPathKey);

  await prefs.remove(AppConstants.profileAvatarPathKey);
  await prefs.remove(AppConstants.profile1cPhotoPathKey);
  await prefs.remove(AppConstants.passwordResetCooldownUntilMsKey);
  await prefs.remove(AppConstants.certificateOrdersPrefsKey);

  for (final p in [avatarPath, oneCPath]) {
    if (p == null || p.trim().isEmpty) continue;
    try {
      await File(p).delete();
    } catch (_) {}
  }
}
