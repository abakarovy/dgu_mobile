import 'dart:async';

import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/network/app_network_banner_controller.dart';
import 'package:dgu_mobile/core/push/push_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

/// Стартовая страница: прогревает кэш под нативным splash и открывает приложение.
/// Пока идёт загрузка (в т.ч. после входа с экрана логина), показываем индикатор —
/// иначе после снятия splash виден пустой белый экран.
class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key});

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Если не залогинен — сразу на логин.
    final isLoggedIn = await AppContainer.authRepository.isLoggedIn();
    if (!isLoggedIn) {
      FlutterNativeSplash.remove();
      if (mounted) context.go('/login');
      return;
    }

    final offline = await AppNetworkBannerController.checkDeviceOffline();
    final allOk = await AppContainer.prefetchAll();
    // При 401 на /auth/me сессию очищает Dio + UnauthorizedHandler; тогда не залогинен — на логин.
    // При таймауте/сети prefetch прервётся без выхода; покажем баннер «сервер не ответил».
    final stillLoggedIn = await AppContainer.authRepository.isLoggedIn();
    if (!stillLoggedIn) {
      FlutterNativeSplash.remove();
      if (mounted) context.go('/login');
      return;
    }
    AppNetworkBannerController.instance
        .applyAfterBootstrap(deviceOffline: offline, allPrefetchOk: allOk);
    FlutterNativeSplash.remove();
    if (mounted) {
      context.go('/app/home');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(PushNavigation.consumePendingIfAny());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

