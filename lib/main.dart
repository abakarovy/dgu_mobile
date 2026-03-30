import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/app.dart';
import 'core/di/app_container.dart';
import 'core/logging/app_log_file.dart';
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

  // Backend config lives in assets/env/.env so it exists on device.
  await dotenv.load(fileName: 'assets/env/.env', isOptional: true);

  // Firebase is optional for backend API, but enable when configured.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  // DI for backend (Dio/AuthApi/TokenStorage).
  await AppContainer.init();

  await _requestNotificationsPermissionIfNeeded();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.green,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,

  ));

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
