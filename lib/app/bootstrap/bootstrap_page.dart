import 'dart:async';

import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/network/app_network_banner_controller.dart';
import 'package:dgu_mobile/core/push/push_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

import 'app_splash_view.dart';

/// Splash ≥5 с, prefetch до 10 с, затем гостевой режим или ЛК.
class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key});

  static const Duration kMinSplash = Duration(seconds: 5);
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
    if (!isLoggedIn) {
      final offline = await AppNetworkBannerController.checkDeviceOffline();
      final allOk = await AppContainer.prefetchPublicDuringSplash(
        minimumDisplay: BootstrapPage.kMinSplash,
        maximumWait: BootstrapPage.kMaxPrefetch,
      );
      AppNetworkBannerController.instance.applyAfterBootstrap(
        deviceOffline: offline,
        allPrefetchOk: allOk,
      );
      if (mounted) context.go('/public/home');
      return;
    }

    final offline = await AppNetworkBannerController.checkDeviceOffline();
    final allOk = await AppContainer.prefetchDuringSplash(
      minimumDisplay: BootstrapPage.kMinSplash,
      maximumWait: BootstrapPage.kMaxPrefetch,
    );

    final stillLoggedIn = await AppContainer.authRepository.isLoggedIn();
    if (!stillLoggedIn) {
      if (mounted) context.go('/public/home');
      return;
    }

    AppNetworkBannerController.instance.applyAfterBootstrap(
      deviceOffline: offline,
      allPrefetchOk: allOk,
    );

    if (mounted) {
      context.go('/app/home');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(PushNavigation.consumePendingIfAny());
      });
    }
  }

  @override
  Widget build(BuildContext context) => const AppSplashView();
}
