import 'dart:async';

import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/network/app_network_banner_controller.dart';
import 'package:dgu_mobile/core/push/push_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

import 'app_splash_view.dart';

/// Белый экран на долю секунды, затем сразу гость или ЛК; prefetch — в фоне.
class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key});

  static const Duration kMaxPrefetch = Duration(seconds: 10);

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      unawaited(_boot());
    });
  }

  Future<void> _boot() async {
    final isLoggedIn = await AppContainer.authRepository.isLoggedIn();
    final offline = await AppNetworkBannerController.checkDeviceOffline();

    if (!isLoggedIn) {
      if (mounted) context.go('/public/home');
      unawaited(_prefetchGuest(offline));
      return;
    }

    if (!await AppContainer.authRepository.isLoggedIn()) {
      if (mounted) context.go('/public/home');
      return;
    }

    if (mounted) {
      context.go('/app/home');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(PushNavigation.consumePendingIfAny());
      });
    }
    unawaited(_prefetchLoggedIn(offline));
  }

  Future<void> _prefetchGuest(bool offline) async {
    final allOk = await AppContainer.prefetchPublicDuringSplash(
      minimumDisplay: Duration.zero,
      maximumWait: BootstrapPage.kMaxPrefetch,
    );
    AppNetworkBannerController.instance.applyAfterBootstrap(
      deviceOffline: offline,
      allPrefetchOk: allOk,
    );
  }

  Future<void> _prefetchLoggedIn(bool offline) async {
    final allOk = await AppContainer.prefetchDuringSplash(
      minimumDisplay: Duration.zero,
      maximumWait: BootstrapPage.kMaxPrefetch,
    );
    AppNetworkBannerController.instance.applyAfterBootstrap(
      deviceOffline: offline,
      allPrefetchOk: allOk,
    );
  }

  @override
  Widget build(BuildContext context) => const AppSplashView();
}
