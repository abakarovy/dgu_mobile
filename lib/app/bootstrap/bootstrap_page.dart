import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/network/app_network_banner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

/// Стартовая страница: прогревает кэш под нативным splash и открывает приложение без лоадеров.
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
    AppNetworkBannerController.instance
        .applyAfterBootstrap(deviceOffline: offline, allPrefetchOk: allOk);
    FlutterNativeSplash.remove();
    if (mounted) context.go('/app/home');
  }

  @override
  Widget build(BuildContext context) {
    // Пустой экран, пока висит native splash.
    return const Scaffold(body: SizedBox.shrink());
  }
}

