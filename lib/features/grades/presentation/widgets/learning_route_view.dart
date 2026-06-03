import 'dart:async';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/navigation/app_overlay_notifier.dart';
import 'package:dgu_mobile/core/utils/parent_child_name.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../domain/grade_type_labels.dart';
import 'semester_period_selector.dart';

/// Учебный маршрут: `GET /api/1c/curriculum` (кэш `1c:curriculum`).
class LearningRouteView extends StatefulWidget {
  const LearningRouteView({super.key});

  @override
  State<LearningRouteView> createState() => _LearningRouteViewState();
}

class _LearningRouteViewState extends State<LearningRouteView> {
  bool _loading = false;
  List<_RouteRow> _allRows = const [];
  int _semesterIndex = 0;
  bool _semesterIndexInitialized = false;

  @override
  void initState() {
    super.initState();
    _reloadFromCache();
    unawaited(_refresh());
  }

  void _reloadFromCache() {
    _allRows = _parseRowsFromCache();
    _clampSemesterIndex();
  }

  List<String> _effectiveSemesters() {
    final set = <String>{};
    for (final r in _allRows) {
      final s = r.semester.trim();
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList()..sort(_compareCurriculumSemesters);
    return list;
  }

  static int? _curriculumSemesterSortKey(String raw) {
    final t = raw.trim().toLowerCase().replaceAll('ё', 'е');
    final m = RegExp(r'^(\d+)\s*сем').firstMatch(t);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  static int _compareCurriculumSemesters(String a, String b) {
    final ka = _curriculumSemesterSortKey(a);
    final kb = _curriculumSemesterSortKey(b);
    if (ka != null && kb != null) return kb.compareTo(ka);
    if (ka != null) return -1;
    if (kb != null) return 1;
    return b.compareTo(a);
  }

  void _clampSemesterIndex() {
    final sems = _effectiveSemesters();
    if (sems.isEmpty) {
      _semesterIndex = 0;
      _semesterIndexInitialized = false;
      return;
    }
    if (!_semesterIndexInitialized) {
      _semesterIndex = 0;
      _semesterIndexInitialized = true;
    } else if (_semesterIndex >= sems.length) {
      _semesterIndex = 0;
    }
  }

  bool _canGoPrevSemester() {
    final n = _effectiveSemesters().length;
    if (n <= 1) return false;
    return _semesterIndex < n - 1;
  }

  bool _canGoNextSemester() {
    final n = _effectiveSemesters().length;
    if (n <= 1) return false;
    return _semesterIndex > 0;
  }

  void _prevSemester() {
    if (!_canGoPrevSemester()) return;
    setState(() => _semesterIndex += 1);
  }

  void _nextSemester() {
    if (!_canGoNextSemester()) return;
    setState(() => _semesterIndex -= 1);
  }

  String _semesterLabel() {
    final sems = _effectiveSemesters();
    if (sems.isEmpty) return 'Семестр';
    return sems[_semesterIndex.clamp(0, sems.length - 1)];
  }

  List<_RouteRow> _rowsForSelectedSemester() {
    final sems = _effectiveSemesters();
    if (sems.isEmpty) return _allRows;
    final selected = sems[_semesterIndex.clamp(0, sems.length - 1)];
    return _allRows.where((r) => r.semester.trim() == selected).toList();
  }

  Future<void> _showSemesterPicker() async {
    final semesters = _effectiveSemesters();
    if (semesters.isEmpty) return;
    final currentIdx = _semesterIndex.clamp(0, semesters.length - 1);

    await AppOverlayNotifier.wrapModalBottomSheet<void>(() {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        useRootNavigator: true,
        barrierColor: Colors.black54,
        builder: (ctx) {
          final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
          final maxH = MediaQuery.sizeOf(ctx).height * 0.55;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surfaceLight,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppUi.radiusXl),
                  ),
                ),
                child: SizedBox(
                  height: maxH,
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 4, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Семестр',
                                style: AppTextStyle.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close, color: AppColors.caption),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: semesters.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final label = semesters[i];
                            final selected = i == currentIdx;
                            return Material(
                              color: selected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  setState(() {
                                    _semesterIndex = i;
                                    _semesterIndexInitialized = true;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    label,
                                    style: AppTextStyle.inter(
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      int? sid;
      if (ParentChildName.isParentRole()) {
        sid = await ParentChildName.ensureChildStudentIdLoaded();
        if (sid == null) {
          if (mounted) setState(() => _loading = false);
          return;
        }
      }
      final raw = await AppContainer.profile1cApi.getCurriculum(studentId: sid);
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
      if (mounted) {
        setState(() {
          _loading = false;
          _reloadFromCache();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rowsForSelectedSemester();
    final semesters = _effectiveSemesters();
    final showSelector = semesters.length > 1;

    if (_loading && _allRows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allRows.isEmpty) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSelector)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: SemesterPeriodSelector(
              periodLabel: _semesterLabel(),
              onPrev: _prevSemester,
              onNext: _nextSemester,
              onTap: _showSemesterPicker,
              canGoPrev: _canGoPrevSemester(),
              canGoNext: _canGoNextSemester(),
            ),
          ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: rows.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(8, 24, 8, 24),
                    children: [
                      Text(
                        'Нет дисциплин за выбранный семестр',
                        textAlign: TextAlign.center,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: AppColors.caption,
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    children: [
                      for (final r in rows) ...[
                        _DisciplineRouteCard(item: r),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  List<_RouteRow> _parseRowsFromCache() {
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
    for (final k in ['curriculum', 'items', 'disciplines', 'subjects', 'rows', 'data']) {
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
      semester: s(m['semester']).trim(),
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
    required this.semester,
    required this.controlForm,
    required this.hours,
    required this.hasHoursPayload,
  });

  final String title;
  final String semester;
  final String controlForm;
  final _CurriculumHours hours;
  final bool hasHoursPayload;
}

class _DisciplineRouteCard extends StatelessWidget {
  const _DisciplineRouteCard({required this.item});

  static const double _pillGap = 6;

  final _RouteRow item;

  static String _controlFormLabel(String raw) {
    final short = GradeTypeLabels.displayLabel(raw);
    return short.isNotEmpty ? short : raw;
  }

  /// Вес для [Expanded]: доля ширины строки ≈ доле текста, без обрезки.
  static int _flexWeight(double intrinsicWidth) {
    return intrinsicWidth.round().clamp(1, 100000);
  }

  /// Индексы чипов, сгруппированные в строки по доступной ширине.
  static List<List<int>> _packRows(List<double> widths, double maxW, double gap) {
    final rows = <List<int>>[];
    var i = 0;
    while (i < widths.length) {
      final row = <int>[];
      var sum = 0.0;
      while (i < widths.length) {
        final w = widths[i];
        final add = row.isEmpty ? w : w + gap;
        if (sum + add > maxW + 0.5) {
          if (row.isEmpty) {
            row.add(i);
            i++;
          }
          break;
        }
        row.add(i);
        sum += add;
        i++;
      }
      if (row.isEmpty) break;
      rows.add(row);
    }
    return rows;
  }

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
            text: 'Форма сдачи • ${_controlFormLabel(item.controlForm)}',
            variant: _RoutePillVariant.form,
            stretch: true,
          ),
          if (item.hasHoursPayload) ...[
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final hourPills = <({String text, _RoutePillVariant variant})>[
                  (
                    text: 'Всего ${item.hours.total} ч.',
                    variant: _RoutePillVariant.totalHours,
                  ),
                  (
                    text: 'Лекции: ${item.hours.theoryLectures}',
                    variant: _RoutePillVariant.hours,
                  ),
                  (text: 'Лаб: ${item.hours.lab}', variant: _RoutePillVariant.hours),
                  (
                    text: 'Практика: ${item.hours.practical}',
                    variant: _RoutePillVariant.hours,
                  ),
                  (
                    text: 'Самостоятельная работа: ${item.hours.independent}',
                    variant: _RoutePillVariant.hours,
                  ),
                ];
                final maxW = constraints.maxWidth;
                final widths = [
                  for (final p in hourPills)
                    _RoutePill.intrinsicWidth(context, p.text),
                ];
                // Чуть завышаем ширину только для раскладки — в ряд не кладём «впритык».
                final packWidths = [for (final w in widths) w + 4];
                final rowIndices = _packRows(packWidths, maxW, _pillGap);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var r = 0; r < rowIndices.length; r++) ...[
                      if (r > 0) const SizedBox(height: _pillGap),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var c = 0; c < rowIndices[r].length; c++) ...[
                            if (c > 0) const SizedBox(width: _pillGap),
                            Expanded(
                              flex: _flexWeight(
                                widths[rowIndices[r][c]],
                              ),
                              child: _RoutePill(
                                text: hourPills[rowIndices[r][c]].text,
                                variant: hourPills[rowIndices[r][c]].variant,
                                stretch: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                );
              },
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
        return (const Color(0x1E7C3AED), const Color(0xFF7C3AED), const Color(0xFF7C3AED));
      case _RoutePillVariant.hours:
        return (const Color(0x1464748B), const Color(0xFF64748B), const Color(0xFF64748B));
    }
  }

  static double intrinsicWidth(BuildContext context, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTextStyle.inter(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    // padding 10×2 + border 0.5×2
    return 21 + tp.width;
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
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: AppTextStyle.inter(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          height: 1.2,
          color: tc,
        ),
      ),
    );
  }
}
