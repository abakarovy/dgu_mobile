import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/app_container.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/api/api_exception.dart';

/// Ошибка «зачётки нет в списках колледжа» (verify-1c / register).
bool isStudentBookNotFoundRegistrationError({
  required String message,
  int? statusCode,
}) {
  if (statusCode == 404) return true;
  final m = message.toLowerCase();
  return m.contains('зачётн') &&
      (m.contains('списках') ||
          m.contains('приёмн') ||
          m.contains('приемн') ||
          m.contains('комисси'));
}

/// Диалог с текстом ошибки и кнопкой отправки в поддержку (registration-report).
Future<void> showRegistrationBookNotFoundDialog({
  required BuildContext context,
  required String errorMessage,
  required String fullName,
  required String studentBookNumber,
  required String source,
  String? lastName,
  String? firstName,
  String? patronymic,
  String? registrationEmail,
  String dialogTitle = 'Не удалось проверить данные',
  bool offerSupportButton = true,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          dialogTitle,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            height: 1.2,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          errorMessage,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 1.35,
            color: AppColors.grey,
          ),
        ),
        actions: [
          if (offerSupportButton)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (!context.mounted) return;
                await submitRegistrationSupportReport(
                  context: context,
                  source: source,
                  message: errorMessage,
                  fullName: fullName,
                  studentBookNumber: studentBookNumber,
                  lastName: lastName,
                  firstName: firstName,
                  patronymic: patronymic,
                  registrationEmail: registrationEmail,
                );
              },
              child: Text(
                'Отправить в поддержку',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.0,
                  color: const Color(0xFF2E63D5),
                ),
              ),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E63D5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(46),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Ок',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> submitRegistrationSupportReport({
  required BuildContext context,
  required String source,
  required String message,
  required String fullName,
  required String studentBookNumber,
  String? lastName,
  String? firstName,
  String? patronymic,
  String? registrationEmail,
}) async {
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(),
        ),
      ),
    ),
  );

  try {
    final serverMsg =
        await AppContainer.authRepository.submitRegistrationSupportReport(
      source: source,
      message: message.trim().isEmpty
          ? 'Зачётная книжка не найдена в списках колледжа.'
          : message,
      fullName: fullName,
      studentBookNumber: studentBookNumber,
      lastName: lastName,
      firstName: firstName,
      patronymic: patronymic,
      registrationEmail: registrationEmail,
      errorCode: 'NOT_FOUND',
    );
    if (context.mounted) Navigator.of(context).pop();
    if (!context.mounted) return;
    await _showResultDialog(
      context: context,
      title: 'Готово',
      message: serverMsg,
    );
  } on ApiException catch (e) {
    if (context.mounted) Navigator.of(context).pop();
    if (!context.mounted) return;
    await _showResultDialog(
      context: context,
      title: 'Не удалось отправить',
      message: e.message,
    );
  } on NetworkException catch (e) {
    if (context.mounted) Navigator.of(context).pop();
    if (!context.mounted) return;
    await _showResultDialog(
      context: context,
      title: 'Нет соединения',
      message: e.message,
    );
  }
}

Future<void> _showResultDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: Text(
        title,
        style: AppTextStyle.inter(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: AppTextStyle.inter(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          height: 1.35,
          color: AppColors.grey,
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E63D5),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Ок',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}
