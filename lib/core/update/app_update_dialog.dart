import 'package:flutter/foundation.dart';
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

    final runtime = AppRuntimeInfo.instance;
    await runtime.ensureLoaded();
    final forced = update.isForcedFor(runtime.version);

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
              platformId: runtime.platformId,
              onLater: () async {
                await AppUpdateController.dismissOptional();
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
            ),
          ),
        );
      },
    );
  }

  static Future<void> _openStoreUrl(String? url) async {
    final s = url?.trim() ?? '';
    if (s.isEmpty) return;
    final uri = Uri.tryParse(s);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _StoreButtonConfig {
  const _StoreButtonConfig({
    required this.label,
    required this.url,
    required this.primary,
  });

  final String label;
  final String? url;
  final bool primary;

  bool get enabled => url != null && url!.trim().isNotEmpty;
}

final class _UpdateDialogCopy {
  _UpdateDialogCopy._();

  static const String _appTitle = 'Колледж ДГУ';

  static List<_StoreButtonConfig> storeButtons(
    AppUpdateInfo update, {
    required String platformId,
  }) {
    final rustore = update.storeUrlRustore?.trim();
    final googlePlay = update.storeUrlAndroid?.trim();
    final appStore = update.storeUrlIos?.trim();

    if (platformId == 'ios' || defaultTargetPlatform == TargetPlatform.iOS) {
      return [
        _StoreButtonConfig(
          label: 'Обновить через App Store',
          url: appStore,
          primary: true,
        ),
      ];
    }

    return [
      _StoreButtonConfig(
        label: 'Обновить через RuStore',
        url: rustore,
        primary: true,
      ),
      _StoreButtonConfig(
        label: 'Обновить через Google Play',
        url: googlePlay,
        primary: false,
      ),
    ];
  }

  static String buildMessage({
    required AppUpdateInfo update,
    required bool forced,
  }) {
    final server = update.message?.trim();
    if (server != null && server.isNotEmpty) return server;

    if (forced) {
      return 'Для продолжения работы нужно обновить приложение «$_appTitle».\n\n'
          'Это обязательное обновление: без него приложение может работать некорректно.';
    }

    return 'Вышла новая версия приложения «$_appTitle».\n\n'
        'Рекомендуем обновиться, чтобы получить исправления и улучшения. '
        'Выберите магазин, через который вы устанавливали приложение.';
  }
}

class _AppUpdateDialogBody extends StatelessWidget {
  const _AppUpdateDialogBody({
    required this.update,
    required this.forced,
    required this.platformId,
    required this.onLater,
  });

  final AppUpdateInfo update;
  final bool forced;
  final String platformId;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final message = _UpdateDialogCopy.buildMessage(
      update: update,
      forced: forced,
    );
    final stores = _UpdateDialogCopy.storeButtons(update, platformId: platformId)
        .where((s) => s.enabled)
        .toList();

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
            message,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 1.45,
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
          if (stores.isEmpty)
            Text(
              'Ссылки на магазин временно недоступны. Попробуйте позже или обратитесь в поддержку колледжа.',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.35,
                color: AppColors.notificationSubtitle,
              ),
            )
          else
            ...stores.asMap().entries.map((entry) {
              final store = entry.value;
              final isLast = entry.key == stores.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: store.primary
                    ? FilledButton(
                        onPressed: () => AppUpdateDialog._openStoreUrl(store.url),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _storeLabel(store.label, Colors.white),
                      )
                    : OutlinedButton(
                        onPressed: () => AppUpdateDialog._openStoreUrl(store.url),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _storeLabel(store.label, AppColors.primaryBlue),
                      ),
              );
            }),
        ],
      ),
    );
  }

  Widget _storeLabel(String text, Color color) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTextStyle.inter(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        height: 1.2,
        color: color,
      ),
    );
  }
}
