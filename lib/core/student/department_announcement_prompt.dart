import 'dart:async';
import 'dart:math' as math;

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefsLastSeenDeptAnnMaxId = 'dept_ann_last_seen_max_id';

/// После входа в оболочку приложения: если для студента есть более новое объявление отделения — показываем диалог.
class DepartmentAnnouncementPrompt {
  DepartmentAnnouncementPrompt._();

  static bool _scheduledThisSession = false;
  static bool _inFlight = false;

  static void scheduleForShell(BuildContext context) {
    if (_scheduledThisSession) return;
    _scheduledThisSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      unawaited(runIfNeeded(context));
    });
  }

  static void resetSessionScheduling() {
    _scheduledThisSession = false;
    _inFlight = false;
  }

  static Future<void> runIfNeeded(BuildContext context) async {
    if (_inFlight) return;
    final me = AppContainer.jsonCache.getJsonMap('auth:me');
    final role = '${me?['role'] ?? ''}'.trim().toLowerCase();
    if (role != 'student') return;

    _inFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenMax = prefs.getInt(_kPrefsLastSeenDeptAnnMaxId) ?? 0;

      final raw = await AppContainer.studentServicesApi.departmentAnnouncementsMy();
      if (raw.isEmpty) return;
      if (!context.mounted) return;

      int idOf(Map<String, dynamic> m) {
        final v = m['id'];
        if (v is int) return v;
        if (v is num) return v.toInt();
        return 0;
      }

      DateTime? tsOf(Map<String, dynamic> m) =>
          DateTime.tryParse('${m['created_at'] ?? m['published_at'] ?? m['updated_at'] ?? ''}');

      final list = List<Map<String, dynamic>>.from(raw);
      final apiMaxId = list.map(idOf).reduce(math.max);
      if (apiMaxId <= lastSeenMax) return;

      final toShow = list.firstWhere((e) => idOf(e) == apiMaxId, orElse: () => list.first);

      final title = '${toShow['title'] ?? 'Объявление отделения'}'.trim();
      final body = '${toShow['body'] ?? ''}'.trim();
      final code = '${toShow['group_code'] ?? ''}'.trim();
      final ts = tsOf(toShow);

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              'Новое объявление',
              style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (code.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          code,
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  if (ts != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(ts.toLocal()),
                      style: AppTextStyle.inter(fontSize: 12, color: AppColors.notificationSubtitle),
                    ),
                  ],
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      body,
                      style: AppTextStyle.inter(fontSize: 14, height: 1.4, color: AppColors.grey),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Закрыть', style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (context.mounted) context.push('/app/student/announcements');
                },
                child: const Text('Все объявления'),
              ),
            ],
          );
        },
      );

      await _setLastSeenMax(prefs, apiMaxId);
    } catch (_) {
    } finally {
      _inFlight = false;
    }
  }

  static Future<void> _setLastSeenMax(SharedPreferences prefs, int apiMaxId) async {
    final cur = prefs.getInt(_kPrefsLastSeenDeptAnnMaxId) ?? 0;
    if (apiMaxId > cur) await prefs.setInt(_kPrefsLastSeenDeptAnnMaxId, apiMaxId);
  }

  /// Вызвать после успешной загрузки списка на экране «все объявления», чтобы не показывать снова то, что пользователь уже открыл в ленте.
  static Future<void> acknowledgeCurrentList(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    int idOf(Map<String, dynamic> m) {
      final v = m['id'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    final apiMaxId = items.map(idOf).reduce(math.max);
    if (apiMaxId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await _setLastSeenMax(prefs, apiMaxId);
  }
}
