import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/staff/staff_web_handoff.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import 'staff_admin_dialog.dart';
import 'staff_admin_ui.dart';

/// Диалог перед переходом на сайт для создания/редактирования новости или мероприятия.
Future<void> showStaffWebEditDialog({
  required BuildContext context,
  required bool isNews,
  required bool isCreate,
  int? resourceId,
}) async {
  final kind = isNews ? 'новости' : 'мероприятия';
  final action = isCreate ? 'Создание' : 'Редактирование';

  final confirmed = await showStaffCenteredDialog<bool>(
    context,
    child: StaffAdminDialogFrame(
      title: '$action на сайте',
      onClose: () => Navigator.of(context).pop(false),
      body: Text(
        '$action $kind выполняется в админке на сайте college.dgu.ru.\n\n'
        'Сейчас вы будете перенаправлены в браузер — вход выполнится автоматически.',
        style: AppTextStyle.inter(
          fontSize: 14,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          StaffAdminUi.outlineButton(
            label: 'Отмена',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: 10),
          StaffAdminUi.darkButton(
            label: 'Перейти на сайт',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;

  unawaited(
    _openHandoffOnSite(
      context: context,
      isNews: isNews,
      isCreate: isCreate,
      resourceId: resourceId,
    ),
  );
}

Future<void> _openHandoffOnSite({
  required BuildContext context,
  required bool isNews,
  required bool isCreate,
  int? resourceId,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(28),
        child: CircularProgressIndicator(),
      ),
    ),
  );

  try {
    final url = await AppContainer.staffApi.createWebHandoffUrl(
      target: StaffWebHandoff.target(isNews: isNews, isCreate: isCreate),
      resourceId: isCreate ? null : resourceId,
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      throw ApiException('Не удалось открыть браузер');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on ApiException catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось открыть редактор на сайте')),
    );
  }
}
