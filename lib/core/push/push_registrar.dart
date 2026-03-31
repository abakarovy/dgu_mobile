import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/logging/app_log_file.dart';
import '../../core/di/app_container.dart';

class PushRegistrar {
  PushRegistrar._();

  static final PushRegistrar instance = PushRegistrar._();

  /// Регистрирует текущий FCM-токен на бэке (если Firebase включён).
  Future<void> ensureRegistered() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;
      final platform = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'web');
      await AppContainer.pushApi.registerDevice(token: token, platform: platform);
      AppLogFile.writeln('[PUSH] registered token (len=${token.length}) platform=$platform');
    } catch (e) {
      AppLogFile.writeln('[PUSH] register failed: $e');
    }
  }

  /// Отвязывает текущий FCM-токен от пользователя на бэке.
  Future<void> unregisterCurrentDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;
      await AppContainer.pushApi.unregisterDevice(token: token);
      AppLogFile.writeln('[PUSH] unregistered token (len=${token.length})');
    } catch (e) {
      AppLogFile.writeln('[PUSH] unregister failed: $e');
    }
  }
}

