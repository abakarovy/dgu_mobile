import 'dart:async';

import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/network/app_network_banner_controller.dart';
import 'package:dgu_mobile/core/navigation/home_refresh_host.dart';
import 'package:dgu_mobile/core/push/push_navigation.dart';
import 'package:dgu_mobile/core/update/app_update_controller.dart';
import 'package:dgu_mobile/core/update/app_update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

import 'app_splash_view.dart';

/// Splash с прогревом кэша; после входа — переход в ЛК только когда данные готовы.
class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key});

  static const Duration kMaxPrefetch = Duration(seconds: 12);

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
    await _runHealthAndUpdateCheck();
    if (!mounted) return;

    if (AppUpdateController.shouldBlockNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(AppUpdateDialog.showPendingIfNeeded());
      });
      return;
    }

    final isLoggedIn = await AppContainer.authRepository.isLoggedIn();
    final offline = await AppNetworkBannerController.checkDeviceOffline();

    if (!isLoggedIn) {
      if (mounted) context.go('/public/home');
      unawaited(_prefetchGuest(offline));
      _showOptionalUpdateAfterNavigation();
      return;
    }

    await _prefetchLoggedIn(offline);

    if (!mounted) return;
    if (!await AppContainer.authRepository.isLoggedIn()) {
      if (mounted) context.go('/public/home');
      _showOptionalUpdateAfterNavigation();
      return;
    }

    if (!mounted) return;
    context.go('/app/home');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HomeRefreshHost.requestRefresh(force: true);
      unawaited(PushNavigation.consumePendingIfAny());
    });
    _showOptionalUpdateAfterNavigation();
  }

  Future<void> _runHealthAndUpdateCheck() async {
    try {
      final health = await AppContainer.healthApi.check();
      await AppUpdateController.ingest(health);
    } catch (_) {
      await AppUpdateController.ingest(null);
    }
  }

  void _showOptionalUpdateAfterNavigation() {
    if (AppUpdateController.shouldBlockNavigation) return;
    if (AppUpdateController.pending == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AppUpdateDialog.showPendingIfNeeded());
    });
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
      minimumDisplay: const Duration(milliseconds: 400),
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
