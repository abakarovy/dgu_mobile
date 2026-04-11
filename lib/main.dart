import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/auth/unauthorized_handler.dart';
import 'core/di/app_container.dart';
import 'moc/mock_mode.dart';
import 'core/logging/app_log_file.dart';
import 'core/push/push_registrar.dart';
import 'core/realtime/realtime_ws_client.dart';
import 'firebase_options.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await AppLogFile.prepareNewSession();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogFile.writeln('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) {
      AppLogFile.writeln(details.stack.toString());
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogFile.writeln('Uncaught async: $error');
    AppLogFile.writeln(stack.toString());
    return true;
  };

  // Базовые значения из репозитория; при наличии `assets/env/.env` — переопределение.
  await dotenv.load(fileName: 'assets/env/.env.example');
  await dotenv.load(
    fileName: 'assets/env/.env',
    mergeWith: dotenv.env,
    isOptional: true,
  );

  /// `true` — данные из `lib/moc`, HTTP к бэкенду не выполняется ([MockDioInterceptor]).
  /// `false` — реальный API ([ApiConstants.baseUrl]).
  // Переключатель моков (можно вручную менять на true/false).
  // Если хочешь включать через команду запуска, верни вариант с `--dart-define=USE_MOCK_BACKEND=true`.
  const kUseMockBackend = false;
  useMockBackend = kUseMockBackend;

  // Firebase is optional for backend API, but enable when configured.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  // DI for backend (Dio/AuthApi/TokenStorage).
  await AppContainer.init();

  UnauthorizedHandler.register(() async {
    // Можем получить 401 в bootstrap/prefetch: важно убрать splash и отправить на логин.
    FlutterNativeSplash.remove();
    await AppContainer.forceLogoutLocal();
    appRouter.go('/login');
  });

  await _requestNotificationsPermissionIfNeeded();

  // Сеть после первого кадра: не блокируем старт и не шумим таймаутами до отрисовки UI.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Register current device token (best-effort).
    PushRegistrar.instance.ensureRegistered();
    RealtimeWsClient.instance.connectIfPossible();
  });

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.green,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const App());
}

Future<void> _requestNotificationsPermissionIfNeeded() async {
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (_) {}

  try {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted) {
      await Permission.notification.request();
    }
  } catch (_) {}
}
