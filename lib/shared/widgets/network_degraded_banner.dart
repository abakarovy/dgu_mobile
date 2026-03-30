import 'package:flutter/material.dart';

import '../../core/network/app_network_banner_controller.dart';

/// Красная полоса под статус-баром: нет сети или бэкенд не ответил; справа «Обновить».
class NetworkDegradedBanner extends StatelessWidget {
  const NetworkDegradedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppNetworkBannerController.instance,
      builder: (context, _) {
        final c = AppNetworkBannerController.instance;
        final kind = c.kind;
        if (kind == AppNetworkBannerKind.none) {
          return const SizedBox.shrink();
        }
        final text = kind == AppNetworkBannerKind.offline
            ? 'Нет соединения, данные не актуальны'
            : 'Сервер не отвечает, данные не актуальные';
        return Material(
          color: const Color(0xFFB91C1C),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: c.refreshBusy ? null : () => c.refresh(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: c.refreshBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Обновить'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
