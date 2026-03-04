import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/notification_setting_row.dart';

/// Экран настроек уведомлений: аппбар со стрелкой назад и заголовком «Уведомления»,
/// секции «Основные» и «Дополнительные» с переключателями.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _newGrades = true;
  bool _scheduleChanges = true;
  bool _deadlines = true;
  bool _collegeNews = true;
  bool _curatorMessages = false;

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
          'Уведомления',
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
        padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppUi.spacingXl),
            _buildSectionTitle('ОСНОВНЫЕ'),
            const SizedBox(height: AppUi.spacingM),
            NotificationSettingRow(
              title: 'Новые оценки',
              subtitle: 'Получать уведомления о новых оценках',
              value: _newGrades,
              onChanged: (v) => setState(() => _newGrades = v),
            ),
            const SizedBox(height: 10),
            NotificationSettingRow(
              title: 'Изменения в расписании',
              subtitle: 'Оповещения о переносе пар',
              value: _scheduleChanges,
              onChanged: (v) => setState(() => _scheduleChanges = v),
            ),
            const SizedBox(height: 10),
            NotificationSettingRow(
              title: 'Дедлайны заданий',
              subtitle: 'Напоминания о сроках сдачи',
              value: _deadlines,
              onChanged: (v) => setState(() => _deadlines = v),
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('ДОПОЛНИТЕЛЬНЫЕ'),
            const SizedBox(height: AppUi.spacingM),
            NotificationSettingRow(
              title: 'Новости колледжа',
              subtitle: 'Важные события и объявления',
              value: _collegeNews,
              onChanged: (v) => setState(() => _collegeNews = v),
            ),
            const SizedBox(height: 10),
            NotificationSettingRow(
              title: 'Сообщения от куратора',
              subtitle: 'Прямая связь с наставником',
              value: _curatorMessages,
              onChanged: (v) => setState(() => _curatorMessages = v),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyle.inter(
        fontWeight: FontWeight.w800,
        fontSize: 11,
        height: 16.5 / 11,
        letterSpacing: 1.65,
        color: AppColors.caption,
      ),
    );
  }
}
