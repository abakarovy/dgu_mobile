import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/backend_access/app_unavailable_screen.dart';
import '../core/backend_access/backend_access_controller.dart';
import '../core/backend_access/backend_access_websocket_sync.dart';
import '../core/push/push_navigation.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _retryBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BackendAccessController.instance.addListener(_onAccessChanged);
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

  void _onAccessChanged() {
    unawaited(syncWebSocketWithBackendAccess(
      BackendAccessController.instance.isBackendBlocked,
    ));
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Firebase.apps.isNotEmpty) {
      unawaited(BackendAccessController.instance.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BackendAccessController.instance.removeListener(_onAccessChanged);
    _openedSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshAccess() async {
    setState(() => _retryBusy = true);
    try {
      await BackendAccessController.instance.refresh();
    } finally {
      if (mounted) setState(() => _retryBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Колледж ДГУ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) {
        if (BackendAccessController.instance.isBackendBlocked) {
          return AppUnavailableScreen(
            onRefresh: _refreshAccess,
            busy: _retryBusy,
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
