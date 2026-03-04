import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';

/// Экран «Студенческий билет»: AppBar как у поддержки, контейнер с отступами 24, ФИО, ID, копирование, даты, форма, курс.
class StudentIdPage extends StatelessWidget {
  const StudentIdPage({super.key});

  static const String _fullName = 'Иванов Иван Иванович';
  static const String _id = '22325';
  static const String _validUntil = '31.08.2026';
  static const String _issueDate = '01.09.2022';
  static const String _studyForm = 'Очная';
  static const String _course = '4';

  static TextStyle _valueStyle() {
    return AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      height: 25 / 20,
      color: AppColors.newsDetailTitle,
    );
  }

  static TextStyle _dateValueStyle() {
    return AppTextStyle.inter(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 26 / 16,
      color: AppColors.textPrimary,
    );
  }

  String _copyableText() {
    return '$_fullName\nID: $_id\nДействителен до: $_validUntil\nДата выдачи: $_issueDate\nФорма обучения: $_studyForm\nКурс: $_course';
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _copyableText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные скопированы')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        headerTitle: Text(
          'Студенческий билет',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 24 / 18,
            color: AppColors.textPrimary,
          ),
        ),
        showNotificationIcon: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppUi.screenPaddingH,
          AppUi.spacingXl,
          AppUi.screenPaddingH,
          AppUi.spacingXl,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppUi.spacingXl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppUi.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(context, 'ФИО'),
              const SizedBox(height: 4),
              Text(_fullName, style: _valueStyle()),
              const SizedBox(height: AppUi.spacingXl),
              _label(context, 'ID'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(_id, style: _valueStyle()),
                  const SizedBox(width: AppUi.spacingS),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context),
                    child: SvgPicture.asset(
                      'assets/icons/copy.svg',
                      width: 14,
                      height: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppUi.spacingXl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label(context, 'Действителен до'),
                        const SizedBox(height: 4),
                        Text(_validUntil, style: _dateValueStyle()),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label(context, 'Дата выдачи'),
                        const SizedBox(height: 4),
                        Text(_issueDate, style: _dateValueStyle()),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppUi.spacingXl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label(context, 'Форма обучения'),
                        const SizedBox(height: 4),
                        Text(_studyForm, style: _dateValueStyle()),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label(context, 'Курс'),
                        const SizedBox(height: 4),
                        Text(_course, style: _dateValueStyle()),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyle.inter(
        fontWeight: FontWeight.w400,
        fontSize: 10,
        height: 15 / 10,
        letterSpacing: 0.5,
        color: AppColors.notificationSubtitle,
      ),
    );
  }
}
