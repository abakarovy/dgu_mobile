import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/models/notification_preferences_model.dart';
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
  NotificationPreferencesModel? _prefs;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
    _load();
  }

  void _hydrateFromCache() {
    try {
      final cached = AppContainer.jsonCache.getJsonMap('mobile:notification-preferences');
      if (cached != null) {
        _prefs = NotificationPreferencesModel.fromJson(cached);
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fresh = await AppContainer.notificationPreferencesApi.getMy();
      await AppContainer.jsonCache.setJson(
        'mobile:notification-preferences',
        fresh.toPatchJson(),
      );
      if (mounted) setState(() => _prefs = fresh);
    } catch (_) {
      // keep cache
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _patch(NotificationPreferencesModel patch) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final fresh = await AppContainer.notificationPreferencesApi.patch(patch);
      await AppContainer.jsonCache.setJson(
        'mobile:notification-preferences',
        fresh.toPatchJson(),
      );
      if (mounted) setState(() => _prefs = fresh);
    } catch (e) {
      if (mounted) {
        final msg = (e is ApiException) ? e.message : 'Ошибка';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _prefs ??
        const NotificationPreferencesModel(
          pushNewGrades: true,
          pushScheduleChange: true,
          pushAssignmentDeadlines: true,
          pushCollegeNews: true,
          pushCollegeEvents: true,
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle:
            Text('Уведомления', style: appHeaderNestedTitleStyle),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppUi.spacingXl),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              _buildSectionTitle('ОСНОВНЫЕ'),
              const SizedBox(height: AppUi.spacingM),
              NotificationSettingRow(
                title: 'Новые оценки',
                subtitle: 'Получать уведомления о новых оценках',
                value: p.pushNewGrades,
                onChanged: (v) {
                  final next = p.copyWith(pushNewGrades: v);
                  setState(() => _prefs = next);
                  _patch(next);
                },
              ),
              const SizedBox(height: 10),
              NotificationSettingRow(
                title: 'Изменения в расписании',
                subtitle: 'Оповещения о переносе пар',
                value: p.pushScheduleChange,
                onChanged: (v) {
                  final next = p.copyWith(pushScheduleChange: v);
                  setState(() => _prefs = next);
                  _patch(next);
                },
              ),
              const SizedBox(height: 10),
              NotificationSettingRow(
                title: 'Дедлайны заданий',
                subtitle: 'Напоминания о сроках сдачи',
                value: p.pushAssignmentDeadlines,
                onChanged: (v) {
                  final next = p.copyWith(pushAssignmentDeadlines: v);
                  setState(() => _prefs = next);
                  _patch(next);
                },
              ),
              const SizedBox(height: 28),
              _buildSectionTitle('ДОПОЛНИТЕЛЬНЫЕ'),
              const SizedBox(height: AppUi.spacingM),
              NotificationSettingRow(
                title: 'Новости колледжа',
                subtitle: 'Важные события и объявления',
                value: p.pushCollegeNews,
                onChanged: (v) {
                  final next = p.copyWith(pushCollegeNews: v);
                  setState(() => _prefs = next);
                  _patch(next);
                },
              ),
              const SizedBox(height: 10),
              NotificationSettingRow(
                title: 'Мероприятия',
                subtitle: 'Анонсы мероприятий колледжа',
                value: p.pushCollegeEvents,
                onChanged: (v) {
                  final next = p.copyWith(pushCollegeEvents: v);
                  setState(() => _prefs = next);
                  _patch(next);
                },
              ),
              const SizedBox(height: 18),
              if (_saving)
                Text(
                  'Сохраняем…',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.notificationSubtitle,
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
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
