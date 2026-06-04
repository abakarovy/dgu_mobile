import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_health_response.dart';
import '../device/app_runtime_info.dart';
import 'app_update_controller.dart';

/// Диалог обновления: принудительный (без закрытия) или опциональный (крестик / «Позже»).
abstract final class AppUpdateDialog {
  static const double _radius = 18;

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
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return PopScope(
          canPop: !forced,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop || forced) return;
            await AppUpdateController.dismissOptional();
          },
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radius),
            ),
            child: _AppUpdateDialogBody(
              update: update,
              forced: forced,
              onLater: () async {
                await AppUpdateController.dismissOptional();
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              onUpdate: () => _openStore(update),
            ),
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

class _AppUpdateDialogBody extends StatelessWidget {
  const _AppUpdateDialogBody({
    required this.update,
    required this.forced,
    required this.onLater,
    required this.onUpdate,
  });

  final AppUpdateInfo update;
  final bool forced;
  final VoidCallback onLater;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final latest = update.latestVersion?.trim();
    final defaultMessage = latest != null && latest.isNotEmpty
        ? 'Вышла новая версия $latest. Установите обновление из RuStore или App Store.'
        : 'Вышла новая версия приложения. Установите обновление из магазина.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: forced ? 4 : 0, right: 8),
                  child: Text(
                    update.title ?? 'Доступно обновление',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 1.25,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (!forced)
                IconButton(
                  onPressed: onLater,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.caption,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: 'Закрыть',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            update.message ?? defaultMessage,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 1.4,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 22),
          if (!forced) ...[
            OutlinedButton(
              onPressed: onLater,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.grey,
                side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Позже',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  height: 1.0,
                  color: AppColors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton(
            onPressed: onUpdate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Обновить',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
