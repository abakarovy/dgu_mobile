import 'dart:async';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/platform/native_date_range_picker.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:flutter/material.dart';

import '../models/session_grade_breakdown.dart';
import '../widgets/grades_list_view.dart';
import '../widgets/learning_route_view.dart';
import '../widgets/subject_grades_sheet.dart';
import '../../../grades/domain/entities/grade_entity.dart';

/// Вкладка «Оценки»: 3 таба (Текущие, Сессия, Учебный маршрут).
/// Текущие: выбор периода (неделя по умолчанию), стрелки, календарь; оценки с датами и типами.
class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> with SingleTickerProviderStateMixin {
  static const List<String> _tabLabels = ['Текущие', 'Сессия', 'Маршрут'];

  late TabController _tabController;
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();
  bool _isWeekMode = true;

  static const String _cacheKeyGrades = 'grades:my';

  List<GradeEntity> _grades = const <GradeEntity>[];
  bool _refreshing = false;

  static bool _isSessionType(String? t) {
    final s = (t ?? '').toLowerCase();
    if (s.isEmpty) return false;
    return s.contains('аттестация') ||
        s.contains('экзам') ||
        s.contains('зач') ||
        s.contains('дифф') ||
        s.contains('курсов');
  }

  /// В журнале с бэка часто приходят строки без оценки (grade_value: null) — для «Текущие» их не показываем,
  /// иначе справа остаётся пустой цветной квадрат.
  static bool _hasGradeValue(GradeEntity g) => g.grade.trim().isNotEmpty;

  /// Все оценки по предметам для детализации при нажатии.
  static Map<String, List<GradeListItem>> _groupBySubject(List<GradeListItem> items) {
    final map = <String, List<GradeListItem>>{};
    for (final e in items) {
      map.putIfAbsent(e.subjectName, () => []).add(e);
    }
    return map;
  }

  List<GradeListItem> _filtered(List<GradeListItem> items) {
    final start = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    final end = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day).add(const Duration(days: 1));
    return items.where((e) {
      if (e.date == null) return false;
      final d = DateTime(e.date!.year, e.date!.month, e.date!.day);
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();
  }

  String get _periodLabel {
    if (_rangeStart.day == _rangeEnd.day &&
        _rangeStart.month == _rangeEnd.month &&
        _rangeStart.year == _rangeEnd.year) {
      return '${_rangeStart.day}.${_rangeStart.month.toString().padLeft(2, '0')}.${_rangeStart.year}';
    }
    return '${_rangeStart.day}.${_rangeStart.month.toString().padLeft(2, '0')} — ${_rangeEnd.day}.${_rangeEnd.month.toString().padLeft(2, '0')}.${_rangeEnd.year}';
  }

  void _prevPeriod() {
    setState(() {
      if (_isWeekMode) {
        _rangeStart = _rangeStart.subtract(const Duration(days: 7));
        _rangeEnd = _rangeEnd.subtract(const Duration(days: 7));
      } else {
        _rangeStart = _rangeStart.subtract(const Duration(days: 1));
        _rangeEnd = _rangeEnd.subtract(const Duration(days: 1));
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_isWeekMode) {
        _rangeStart = _rangeStart.add(const Duration(days: 7));
        _rangeEnd = _rangeEnd.add(const Duration(days: 7));
      } else {
        _rangeStart = _rangeStart.add(const Duration(days: 1));
        _rangeEnd = _rangeEnd.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showNativeOrMaterialDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
    );
    if (picked != null && mounted) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
        _isWeekMode = picked.start.difference(picked.end).abs().inDays != 0;
      });
    }
  }

  Future<void> _showDatePickerSheet(BuildContext context) async {
    await _pickDateRange(context);
  }

  void _showSubjectGrades(BuildContext context, String subjectName) {
    // В новой схеме sheet строим из уже загруженных данных (snap.data).
    // Если данных нет — будет пусто.
    final grades = _lastBySubject[subjectName] ?? [];
    if (context.mounted) {
      showSubjectGradesSheet(context, subjectName: subjectName, grades: grades);
    }
  }

  Map<String, List<GradeListItem>> _lastBySubject = const {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    final weekday = now.weekday;
    final mondayOffset = weekday == 7 ? 6 : weekday - 1;
    _rangeStart = now.subtract(Duration(days: mondayOffset));
    _rangeEnd = _rangeStart.add(const Duration(days: 6));

    _grades = _decodeCachedGrades();
    // Тихо обновим из сети, но UI строим сразу по кэшу (чтобы не было «загрузки» при открытии).
    unawaited(_refreshGrades());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              return Container(
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2563EB),
                    width: 1.53,
                  ),
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _GradesTab(
                          label: _tabLabels[i],
                          selected: _tabController.index == i,
                          onTap: () => _tabController.animateTo(i),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _tabController,
          builder: (context, _) {
            final idx = _tabController.index;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_refreshing && _grades.isNotEmpty)
                    const LinearProgressIndicator(minHeight: 2),
                  if (idx == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return _PeriodSelector(
                            periodLabel: _periodLabel,
                            onPrev: _prevPeriod,
                            onNext: _nextPeriod,
                            onTap: () => _showDatePickerSheet(context),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCurrentTab(context),
                        _buildSessionTab(),
                        const LearningRouteView(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context) {
    final currentEntities = _grades
        .where((g) => !_isSessionType(g.gradeType))
        .where(_hasGradeValue)
        .toList();
    final list = currentEntities.map(_toListItem).toList();
    final filtered = _filtered(list);
    _lastBySubject = _groupBySubject(list);

    if (_grades.isEmpty && _refreshing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Нет текущих оценок',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.caption),
        ),
      );
    }
    return GradesListView(
      items: filtered,
      groupByDate: true,
      onSubjectTap: (name) => _showSubjectGrades(context, name),
    );
  }

  Widget _buildSessionTab() {
    final all = _grades.where((g) => _isSessionType(g.gradeType)).toList();
    if (_grades.isEmpty && _refreshing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (all.isEmpty) {
      return Center(
        child: Text(
          'Нет данных сессии',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.caption),
        ),
      );
    }

    final bySubject = <String, List<GradeEntity>>{};
    for (final g in all) {
      bySubject.putIfAbsent(g.subjectName, () => []).add(g);
    }
    final subjects = bySubject.keys.toList()..sort();

    final items = <GradeListItem>[];
    for (final s in subjects) {
      final breakdown = _breakdownFor(bySubject[s]!);
      items.add(
        GradeListItem(
          subjectName: s,
          grade: '',
          subtitle: '',
          sessionBreakdown: breakdown,
        ),
      );
    }

    return GradesListView(items: items);
  }

  SessionGradeBreakdown _breakdownFor(List<GradeEntity> grades) {
    String? pick(bool Function(String s) p) {
      for (final g in grades) {
        final t = (g.gradeType ?? '').toLowerCase();
        if (p(t)) return g.grade;
      }
      return null;
    }

    return SessionGradeBreakdown(
      // Аттестации — бинарный статус (есть/нет), без числовых оценок в UI.
      att1: pick((s) => s.contains('аттестация 1') || s.contains('атт 1')) != null
          ? 'атт'
          : null,
      att2: pick((s) => s.contains('аттестация 2') || s.contains('атт 2')) != null
          ? 'атт'
          : null,
      dfk: pick((s) => s.contains('дифф')),
      kurs: pick((s) => s.contains('курсов')),
      zach: pick((s) => s.contains('зач') && !s.contains('дифф')),
      ekz: pick((s) => s.contains('экзам')),
    );
  }

  GradeListItem _toListItem(GradeEntity e) {
    return GradeListItem(
      subjectName: e.subjectName,
      grade: e.grade,
      subtitle: e.teacherName ?? '',
      date: e.date,
      type: e.gradeType,
    );
  }

  List<GradeEntity> _decodeCachedGrades() {
    final cached = AppContainer.jsonCache.getJsonList(_cacheKeyGrades);
    if (cached == null) return const <GradeEntity>[];
    return cached
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map((j) => GradeEntity(
              subjectName: (j['subject_name'] as String?) ?? '',
              grade: (j['grade'] as String?) ?? '',
              gradeType: (j['grade_type'] as String?),
              teacherName: (j['teacher_name'] as String?),
              date: DateTime.tryParse((j['date'] as String?) ?? ''),
              semester: (j['semester'] as String?),
            ))
        .toList();
  }

  Future<void> _refreshGrades() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final fresh = await AppContainer.gradesApi.getMyGrades();
      final cached = _decodeCachedGrades();
      // При пустом ответе сервера сохраняем старый кэш.
      if (fresh.isNotEmpty || cached.isEmpty) {
        await AppContainer.jsonCache.setJson(
          _cacheKeyGrades,
          [
            for (final g in fresh)
              {
                'subject_name': g.subjectName,
                'grade': g.grade,
                'grade_type': g.gradeType,
                'teacher_name': g.teacherName,
                'date': g.date?.toIso8601String(),
                'semester': g.semester,
              }
          ],
        );
        if (mounted) setState(() => _grades = fresh);
      } else {
        if (mounted) setState(() => _grades = cached);
      }
    } catch (_) {
      final cached = _decodeCachedGrades();
      if (mounted && cached.isNotEmpty) setState(() => _grades = cached);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}

const double _dateControlHeight = 30;

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periodLabel,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  final String periodLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _dateControlHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF2147B6),
              Color(0xFF3779EC),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2249B9),
            width: 0.36,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onPrev,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.chevron_left, size: 18, color: Colors.white),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Text(
                    periodLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onNext,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.chevron_right, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradesTab extends StatelessWidget {
  const _GradesTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF2563EB) : Colors.transparent;
    final textColor = selected ? Colors.white : const Color(0xFF2563EB);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 10.44,
              height: 1.0,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
