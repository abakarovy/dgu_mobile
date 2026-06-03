import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

import 'app/app.dart';
import 'core/ads/yandex_ads_config.dart';
import 'app/router/app_router.dart';
import 'core/auth/unauthorized_handler.dart';
import 'core/di/app_container.dart';
import 'core/backend_access/backend_access_controller.dart';
import 'core/backend_access/backend_access_websocket_sync.dart';
import 'core/logging/app_log_file.dart';
import 'core/push/push_navigation.dart';
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

  AppLogFile.writeln(
    'старт: API_BASE_URL=${dotenv.env['API_BASE_URL'] ?? '(через ApiConstants)'}',
  );

  if (YandexAdsConfig.showNativeFeedAds) {
    final adWarn = YandexAdsConfig.adUnitIdConfigWarning;
    if (adWarn != null) {
      AppLogFile.writeln(adWarn);
      debugPrint(adWarn);
    }
    try {
      await YandexAds.initialize();
      AppLogFile.writeln(
        'Yandex Ads SDK: adUnitId=${YandexAdsConfig.nativeAdUnitId}',
      );
    } catch (e, st) {
      AppLogFile.writeln('Yandex Ads init пропущен: $e');
      AppLogFile.writeln('$st');
    }
  }

  // Firebase опционален (Windows/Web без конфига — без FCM, без падений).
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    PushNavigation.holdTerminatedLaunchMessage(
      await FirebaseMessaging.instance.getInitialMessage(),
    );
  } catch (e, st) {
    AppLogFile.writeln('Firebase init пропущен: $e');
    AppLogFile.writeln('$st');
  }

  if (firebaseReady) {
    await BackendAccessController.instance.initialize();
  }

  // DI for backend (Dio/AuthApi/TokenStorage).
  await AppContainer.init();

  await syncWebSocketWithBackendAccess(
    BackendAccessController.instance.isBackendBlocked,
  );

  UnauthorizedHandler.register(() async {
    // Можем получить 401 в bootstrap/prefetch: важно убрать splash и отправить на логин.
    FlutterNativeSplash.remove();
    await AppContainer.forceLogoutLocal();
    appRouter.go('/public/profile');
  });

  await _requestNotificationsPermissionIfNeeded(firebaseReady: firebaseReady);

  // Сеть после первого кадра: не блокируем старт и не шумим таймаутами до отрисовки UI.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (firebaseReady) {
      PushRegistrar.attachTokenRefreshListener();
      PushRegistrar.instance.ensureRegistered();
    }
    if (!BackendAccessController.instance.isBackendBlocked) {
      RealtimeWsClient.instance.connectIfPossible();
    }
  });

  // Прозрачный статус-бар: фон задаёт экран (на входе — [assets/images/photo.png]).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const App());
}

Future<void> _requestNotificationsPermissionIfNeeded({required bool firebaseReady}) async {
  if (firebaseReady) {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}
  }

  try {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted) {
      await Permission.notification.request();
    }
  } catch (_) {}
}
