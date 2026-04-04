import 'dart:async';

import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Учебный маршрут: данные с `GET /api/1c/curriculum` (кэш `1c:curriculum`, см. руководство backend).
class LearningRouteView extends StatefulWidget {
  const LearningRouteView({super.key});

  @override
  State<LearningRouteView> createState() => _LearningRouteViewState();
}

class _LearningRouteViewState extends State<LearningRouteView> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final raw = await AppContainer.profile1cApi.getCurriculum();
      if (raw == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (raw is List) {
        await AppContainer.jsonCache.setJson(AppContainer.curriculumCacheKey, raw);
      } else if (raw is Map) {
        await AppContainer.jsonCache.setJson(
          AppContainer.curriculumCacheKey,
          Map<String, dynamic>.from(raw),
        );
      }
    } catch (_) {
      // оставляем кэш
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rowsFromCache();
    if (_loading && rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 48, 8, 24),
          children: [
            Text(
              'Данные маршрута пока недоступны. Потяните вниз для обновления.',
              textAlign: TextAlign.center,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 1.3,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
        children: [
          for (final r in rows) ...[
            _DisciplineRouteCard(item: r),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  List<_RouteRow> _rowsFromCache() {
    final list = AppContainer.jsonCache.getJsonList(AppContainer.curriculumCacheKey);
    if (list != null) {
      return _parseList(list);
    }
    final map = AppContainer.jsonCache.getJsonMap(AppContainer.curriculumCacheKey);
    if (map != null) {
      return _parseMap(map);
    }
    return [];
  }

  List<_RouteRow> _parseList(List<dynamic> list) {
    final out = <_RouteRow>[];
    for (final e in list) {
      if (e is! Map) continue;
      final row = _rowFromMap(Map<String, dynamic>.from(e));
      if (row != null) out.add(row);
    }
    return out;
  }

  List<_RouteRow> _parseMap(Map<String, dynamic> map) {
    for (final k in ['items', 'disciplines', 'curriculum', 'subjects', 'rows', 'data']) {
      final v = map[k];
      if (v is List) return _parseList(v);
    }
    return [];
  }

  _RouteRow? _rowFromMap(Map<String, dynamic> m) {
    String s(dynamic v) => v is String ? v : (v == null ? '' : '$v');
    final title = s(
      m['subject'] ??
          m['discipline'] ??
          m['subject_name'] ??
          m['name'] ??
          m['title'],
    ).trim();
    if (title.isEmpty) return null;
    final form = s(
      m['control_form'] ??
          m['form'] ??
          m['grade_type'] ??
          m['type'] ??
          m['control'] ??
          m['kind'],
    ).trim();
    final rawHours = m['hours'];
    final hasHoursPayload = rawHours is Map;
    final hours = hasHoursPayload ? _parseHours(rawHours) : const _CurriculumHours();
    return _RouteRow(
      title: title,
      controlForm: form.isEmpty ? '—' : form,
      hours: hours,
      hasHoursPayload: hasHoursPayload,
    );
  }

  static _CurriculumHours _parseHours(dynamic raw) {
    if (raw is! Map) return const _CurriculumHours();
    final h = Map<String, dynamic>.from(raw);
    int g(String key) {
      final v = h[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return _CurriculumHours(
      total: g('total'),
      theoryLectures: g('theory_lectures'),
      lab: g('lab'),
      practical: g('practical'),
      independent: g('independent'),
    );
  }
}

class _CurriculumHours {
  const _CurriculumHours({
    this.total = 0,
    this.theoryLectures = 0,
    this.lab = 0,
    this.practical = 0,
    this.independent = 0,
  });

  final int total;
  final int theoryLectures;
  final int lab;
  final int practical;
  final int independent;

}

class _RouteRow {
  const _RouteRow({
    required this.title,
    required this.controlForm,
    required this.hours,
    required this.hasHoursPayload,
  });

  final String title;
  final String controlForm;
  final _CurriculumHours hours;
  final bool hasHoursPayload;
}

class _DisciplineRouteCard extends StatelessWidget {
  const _DisciplineRouteCard({required this.item});

  final _RouteRow item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x24000000), width: 0.46),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            offset: Offset(1.38, 1.84),
            blurRadius: 6.36,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.title,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.0,
              color: const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 10),
          _RoutePill(
            text: 'Форма сдачи • ${item.controlForm}',
            variant: _RoutePillVariant.form,
            stretch: true,
          ),
          if (item.hasHoursPayload) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _RoutePill(
                    text: 'Всего ${item.hours.total} ч.',
                    variant: _RoutePillVariant.totalHours,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RoutePill(
                    text: 'Лекции: ${item.hours.theoryLectures}',
                    variant: _RoutePillVariant.hours,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RoutePill(
                    text: 'Лаб: ${item.hours.lab}',
                    variant: _RoutePillVariant.hours,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _RoutePill(
                    text: 'Практика: ${item.hours.practical}',
                    variant: _RoutePillVariant.hours,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RoutePill(
                    text: 'Самостоятельная работа: ${item.hours.independent}',
                    variant: _RoutePillVariant.hours,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            _RoutePill(
              text: 'Часы • нет данных',
              variant: _RoutePillVariant.hours,
              stretch: true,
            ),
          ],
        ],
      ),
    );
  }
}

enum _RoutePillVariant { form, totalHours, hours }

class _RoutePill extends StatelessWidget {
  const _RoutePill({
    required this.text,
    required this.variant,
    this.stretch = false,
  });

  final String text;
  final _RoutePillVariant variant;
  final bool stretch;

  (Color bg, Color border, Color text) _palette() {
    switch (variant) {
      case _RoutePillVariant.form:
        return (const Color(0x242563EB), const Color(0xFF2563EB), const Color(0xFF2563EB));
      case _RoutePillVariant.totalHours:
        // Отдельный акцент для «всего часов» (не slate, не синий формы).
        return (const Color(0x1E7C3AED), const Color(0xFF7C3AED), const Color(0xFF7C3AED));
      case _RoutePillVariant.hours:
        return (const Color(0x1464748B), const Color(0xFF64748B), const Color(0xFF64748B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, br, tc) = _palette();
    return Container(
      width: stretch ? double.infinity : null,
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.65),
        border: Border.all(color: br, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.inter(
          fontWeight: FontWeight.w700,
          fontSize: 8.65,
          height: 1.15,
          color: tc,
        ),
      ),
    );
  }
}
