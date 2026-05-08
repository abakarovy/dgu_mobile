import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/push/push_navigation.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription<RemoteMessage>? _openedSub;

  @override
  void initState() {
    super.initState();
    if (Firebase.apps.isNotEmpty) {
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        final ctx = appRootNavigatorKey.currentContext;
        if (ctx != null) {
          unawaited(PushNavigation.onNotificationOpened(msg));
        } else {
          PushNavigation.holdTerminatedLaunchMessage(msg);
        }
      });
    }
  }

  @override
  void dispose() {
    _openedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Колледж ДГУ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
