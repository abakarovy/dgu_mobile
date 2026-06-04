import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router/app_router.dart';
import '../../data/models/app_health_response.dart';
import '../device/app_runtime_info.dart';
import 'app_update_controller.dart';

/// Диалог обновления: принудительный (без «Позже») или опциональный.
abstract final class AppUpdateDialog {
  static Future<void> showPendingIfNeeded() async {
    final update = AppUpdateController.pending;
    if (update == null) return;

    await AppRuntimeInfo.instance.ensureLoaded();
    final forced = update.isForcedFor(AppRuntimeInfo.instance.version);

    final ctx = appRootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    await showDialog<void>(
      context: ctx,
      barrierDismissible: !forced,
      builder: (dialogContext) {
        return PopScope(
          canPop: !forced,
          child: AlertDialog(
            title: Text(update.title ?? 'Доступно обновление'),
            content: SingleChildScrollView(
              child: Text(
                update.message ??
                    'Вышла новая версия приложения. Установите обновление из магазина.',
              ),
            ),
            actions: [
              if (!forced)
                TextButton(
                  onPressed: () async {
                    await AppUpdateController.dismissOptional();
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Позже'),
                ),
              FilledButton(
                onPressed: () => _openStore(update),
                child: const Text('Обновить'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _openStore(AppUpdateInfo update) async {
    final url = _resolveStoreUrl(update);
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  static String _resolveStoreUrl(AppUpdateInfo update) {
    if (Platform.isAndroid) {
      return _firstNonEmpty([
        update.storeUrlRustore,
        update.storeUrlAndroid,
      ]);
    }
    if (Platform.isIOS) {
      return update.storeUrlIos ?? '';
    }
    return _firstNonEmpty([
      update.storeUrlRustore,
      update.storeUrlAndroid,
      update.storeUrlIos,
    ]);
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final s = v?.trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '';
  }
}
