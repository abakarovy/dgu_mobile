import 'dart:async';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/utils/parent_child_name.dart';
import 'package:dgu_mobile/core/platform/native_date_range_picker.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/data/models/absences_detail.dart';
import 'package:dgu_mobile/features/grades/domain/entities/grade_entity.dart';
import 'package:dgu_mobile/features/grades/presentation/widgets/grade_item_tile.dart';
import 'package:dgu_mobile/features/grades/presentation/widgets/grades_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/app_header.dart';

/// Экран «Пропуски»: «Текущие» — строки из API absences (`items`) **и** записи журнала 1С с типом «пропуск»
/// (кэш `grades:my`, тот же источник, что у экрана оценок). «Всего часов» — агрегаты по семестрам.
class AbsencesPage extends StatefulWidget {
  const AbsencesPage({super.key});

  @override
  State<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends State<AbsencesPage> with SingleTickerProviderStateMixin {
  static const List<String> _mainTabLabels = ['Текущие', 'Всего часов'];

  late TabController _tabController;
  AbsencesDetail? _detail;
  bool _loading = true;

  int _yearIndex = 0;

  /// Как на экране «Оценки» → «Текущие».
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  bool _isWeekMode = true;

  /// Тот же кэш, что [GradesPage] (`sync-grades` / журнал).
  static const String _cacheKeyGrades = 'grades:my';

  static const _shadowProfile = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(4, 5),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Тень для белой карточки «По уважительной причине».
  static const _shadowExcusedCard = [
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(4.27, 8.54),
      blurRadius: 27.53,
      spreadRadius: 0,
    ),
  ];

  static const Color _excusedCardText = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    _rangeEnd = day;
    _rangeStart = day.subtract(const Duration(days: 13));
    unawaited(_load());
    unawaited(_refreshGradesCache());
  }

  /// Подтянуть журнал и обновить `grades:my` (как в prefetch), иначе список пустой.
  Future<void> _refreshGradesCache() async {
    try {
      int? sid;
      if (ParentChildName.isParentRole()) {
        sid = await ParentChildName.ensureChildStudentIdLoaded();
        if (sid == null) return;
      }
      final bundle = await AppContainer.gradesApi.loadMyGrades(studentIdOverride: sid);
      await AppContainer.jsonCache.setJson(
        _cacheKeyGrades,
        [
          for (final g in bundle.grades)
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
      await AppContainer.jsonCache.setJson('grades:semesters', bundle.semesters);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  List<GradeEntity> _decodeCachedGrades() {
    final cached = AppContainer.jsonCache.getJsonList(_cacheKeyGrades);
    if (cached == null) return const <GradeEntity>[];
    String str(dynamic v) => v is String ? v : (v == null ? '' : '$v');
    return cached
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(
          (j) => GradeEntity(
            subjectName: str(j['subject_name']).trim(),
            grade: str(j['grade']).trim(),
            gradeType: j['grade_type'] != null ? str(j['grade_type']) : null,
            teacherName: j['teacher_name'] != null ? str(j['teacher_name']) : null,
            date: DateTime.tryParse(str(j['date'])),
            semester: j['semester'] != null ? str(j['semester']).trim() : null,
          ),
        )
        .toList();
  }

  static bool _gradeRowIsAbsence(GradeEntity g) {
    final t = (g.gradeType ?? '').toLowerCase();
    return t.contains('пропуск');
  }

  /// Пропуски из журнала (как на экране оценок), в выбранном периоде.
  List<GradeEntity> _journalAbsencesInRange() {
    return _decodeCachedGrades().where((g) {
      if (!_gradeRowIsAbsence(g)) return false;
      final d = g.date;
      if (d == null) return false;
      return _dateInRange(d);
    }).toList();
  }

  static String _formatDayRu(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  List<_MergedCurrentRow> _mergedCurrentRows() {
    final rows = <_MergedCurrentRow>[];
    for (final m in _filteredItemsForCurrent()) {
      final title =
          (m['subject'] ?? m['discipline'] ?? m['title'] ?? 'Пропуск').toString();
      final d = _parseItemDate(m);
      final raw = '${m['date'] ?? m['absence_date'] ?? ''}'.trim();
      final dateLine = d != null ? _formatDayRu(d) : (raw.isNotEmpty ? raw : '');
      rows.add(
        _MergedCurrentRow(
          subjectName: title,
          grade: '-',
          subtitle: '',
          type: dateLine.isNotEmpty ? dateLine : null,
          isSpecialType: false,
          sortDate: d,
        ),
      );
    }
    for (final g in _journalAbsencesInRange()) {
      final d = g.date;
      final gt = (g.gradeType ?? '').trim();
      final tn = (g.teacherName ?? '').trim();
      final gv = g.grade.trim();
      rows.add(
        _MergedCurrentRow(
          subjectName: g.subjectName,
          grade: gv.isEmpty ? '-' : gv,
          subtitle: tn,
          type: gt.isNotEmpty ? gt : null,
          isSpecialType: gt.isNotEmpty && GradeListItem.specialTypes.contains(gt),
          sortDate: d,
        ),
      );
    }
    rows.sort((a, b) {
      if (a.sortDate == null && b.sortDate == null) return 0;
      if (a.sortDate == null) return 1;
      if (b.sortDate == null) return -1;
      return b.sortDate!.compareTo(a.sortDate!);
    });
    return rows;
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

  DateTime? _parseItemDate(Map<String, dynamic> m) {
    for (final k in ['date', 'absence_date', 'day', 'at']) {
      final v = m[k];
      if (v == null) continue;
      if (v is DateTime) {
        return DateTime(v.year, v.month, v.day);
      }
      final s = v.toString();
      var d = DateTime.tryParse(s);
      if (d != null) return DateTime(d.year, d.month, d.day);
      final rx = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})');
      final mm = rx.firstMatch(s);
      if (mm != null) {
        final dd = int.tryParse(mm.group(1)!);
        final mo = int.tryParse(mm.group(2)!);
        final yy = int.tryParse(mm.group(3)!);
        if (dd != null && mo != null && yy != null) {
          return DateTime(yy, mo, dd);
        }
      }
    }
    return null;
  }

  bool _dateInRange(DateTime d) {
    final start = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    final end = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day).add(const Duration(days: 1));
    final dd = DateTime(d.year, d.month, d.day);
    return !dd.isBefore(start) && dd.isBefore(end);
  }

  List<Map<String, dynamic>> _filteredItemsForCurrent() {
    final items = _detail?.items ?? const [];
    return items.where((m) {
      final d = _parseItemDate(m);
      if (d == null) return true;
      return _dateInRange(d);
    }).toList();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      int? sid;
      if (ParentChildName.isParentRole()) {
        sid = await ParentChildName.ensureChildStudentIdLoaded();
        if (sid == null) {
          if (mounted) {
            setState(() {
              _detail = const AbsencesDetail(semesters: []);
              _clampIndices();
            });
          }
          return;
        }
      }
      final d = await AppContainer.profile1cApi.getAbsencesDetail(studentId: sid);
      if (mounted) {
        setState(() {
          _detail = d ?? const AbsencesDetail(semesters: []);
          _clampIndices();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _detail = const AbsencesDetail(semesters: []);
          _clampIndices();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clampIndices() {
    final years = _distinctYears();
    if (_yearIndex >= years.length) _yearIndex = 0;
  }

  /// Начало учебного года: «2024-2025» → 2024 (берём **меньший** год из строки, не последний).
  /// Одна дата «2 семестр 2025» → 2024 (весна уч. года 2024–2025).
  int? _academicYearStart(AbsenceSemesterRow r) {
    if (r.year != null) return r.year;
    final s = r.semester;
    final ms = RegExp(r'(20\d{2})').allMatches(s).map((m) => int.parse(m.group(0)!)).toList();
    if (ms.isEmpty) return null;
    if (ms.length >= 2) {
      return ms.reduce((a, b) => a < b ? a : b);
    }
    final only = ms.first;
    final lower = s.toLowerCase();
    final secondSemester = lower.contains('2 сем') ||
        lower.contains('2-сем') ||
        lower.contains('второй сем') ||
        lower.contains('ii сем');
    if (secondSemester) {
      return only - 1;
    }
    return only;
  }

  List<int> _distinctYears() {
    final rows = _detail?.semesters ?? const <AbsenceSemesterRow>[];
    final ys = <int>{};
    for (final r in rows) {
      final y = _academicYearStart(r);
      if (y != null) ys.add(y);
    }
    if (ys.isEmpty) {
      return <int>[0];
    }
    return (ys.toList()..sort((a, b) => b.compareTo(a)));
  }

  List<AbsenceSemesterRow> _rowsInYear(int yearKey) {
    final rows = _detail?.semesters ?? const <AbsenceSemesterRow>[];
    if (yearKey == 0) return List<AbsenceSemesterRow>.of(rows);
    return rows.where((r) => _academicYearStart(r) == yearKey).toList();
  }

  List<AbsenceSemesterRow> _semestersForSelectedYear() {
    final years = _distinctYears();
    if (years.isEmpty) return const [];
    final y = years[_yearIndex.clamp(0, years.length - 1)];
    return _rowsInYear(y);
  }

  int _selectedYearKey() {
    final years = _distinctYears();
    if (years.isEmpty) return 0;
    return years[_yearIndex.clamp(0, years.length - 1)];
  }

  String _yearPeriodLabel() {
    final y = _selectedYearKey();
    if (y == 0) return 'Период';
    return '$y-${y + 1}';
  }

  /// Сумма часов за год; если часов нет — сумма пропусков (показ как «N пропусков»).
  String _yearTotalDisplay(int yearKey) {
    final list = _rowsInYear(yearKey);
    if (list.isEmpty) return '—';
    var hoursSum = 0.0;
    var anyHours = false;
    var absSum = 0;
    var anyAbs = false;
    for (final r in list) {
      final h = r.totalHours;
      if (h != null) {
        hoursSum += h;
        anyHours = true;
      }
      final a = r.totalAbsences;
      if (a != null) {
        absSum += a;
        anyAbs = true;
      }
    }
    if (anyHours) {
      return _formatHoursRu(hoursSum);
    }
    if (anyAbs) {
      return _formatAbsencesRu(absSum);
    }
    return '—';
  }

  /// Сумма пропусков по уважительной причине за выбранный учебный год.
  String _yearExcusedDisplay(int yearKey) {
    final list = _rowsInYear(yearKey);
    if (list.isEmpty) return '—';
    var sum = 0;
    var any = false;
    for (final r in list) {
      final e = r.excusedAbsences;
      if (e != null) {
        sum += e;
        any = true;
      }
    }
    if (!any) return '—';
    return _formatAbsencesRu(sum);
  }

  void _prevYear() {
    final years = _distinctYears();
    if (years.isEmpty) return;
    setState(() {
      _yearIndex = (_yearIndex - 1 + years.length) % years.length;
    });
  }

  void _nextYear() {
    final years = _distinctYears();
    if (years.isEmpty) return;
    setState(() {
      _yearIndex = (_yearIndex + 1) % years.length;
    });
  }

  static String _formatHoursRu(double? h) {
    if (h == null) return '—';
    final v = h.round();
    final mod10 = v % 10;
    final mod100 = v % 100;
    if (mod100 >= 11 && mod100 <= 14) return '$v часов';
    if (mod10 == 1) return '$v час';
    if (mod10 >= 2 && mod10 <= 4) return '$v часа';
    return '$v часов';
  }

  static String _formatAbsencesRu(int? n) {
    if (n == null) return '—';
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return '$n пропусков';
    if (mod10 == 1) return '$n пропуск';
    if (mod10 >= 2 && mod10 <= 4) return '$n пропуска';
    return '$n пропусков';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Пропуски', style: appHeaderNestedTitleStyle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      for (int i = 0; i < 2; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _AbsencesMainTab(
                            label: _mainTabLabels[i],
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentTab(context),
                _buildTotalHoursTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context) {
    final merged = _mergedCurrentRows();
    final grouped = _groupMergedByDate(merged);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
          child: _AbsencePeriodSelector(
            periodLabel: _periodLabel,
            onPrev: _prevPeriod,
            onNext: _nextPeriod,
            onTap: () => _pickDateRange(context),
          ),
        ),
        Expanded(
          child: merged.isEmpty
              ? Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text(
                          'Нет записей о пропусках за выбранный период',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.caption,
                          ),
                        ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final e in grouped.dateEntries) ...[
                      _AbsenceDateGroupHeader(date: e.$1),
                      ...e.$2.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: _AbsenceCurrentGradeCard(row: row),
                        ),
                      ),
                      const SizedBox(height: AppUi.spacingL),
                    ],
                    if (grouped.noDateRows.isNotEmpty) ...[
                      const _AbsenceDateGroupHeader(date: null),
                      ...grouped.noDateRows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: _AbsenceCurrentGradeCard(row: row),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  /// Группировка по календарному дню, как на экране «Оценки» → «Текущие».
  ({List<(DateTime, List<_MergedCurrentRow>)> dateEntries, List<_MergedCurrentRow> noDateRows})
      _groupMergedByDate(List<_MergedCurrentRow> merged) {
    final byDate = <DateTime, List<_MergedCurrentRow>>{};
    final noDate = <_MergedCurrentRow>[];
    for (final r in merged) {
      if (r.sortDate == null) {
        noDate.add(r);
      } else {
        final d = DateTime(r.sortDate!.year, r.sortDate!.month, r.sortDate!.day);
        byDate.putIfAbsent(d, () => []).add(r);
      }
    }
    final keys = byDate.keys.toList()..sort();
    final dateEntries = <(DateTime, List<_MergedCurrentRow>)>[
      for (final k in keys) (k, byDate[k]!),
    ];
    return (dateEntries: dateEntries, noDateRows: noDate);
  }

  Widget _buildTotalHoursTab(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final sems = _semestersForSelectedYear();
    if (sems.isEmpty && !(_detail?.semesters.isEmpty ?? true)) {
      return Center(
        child: Text(
          'Нет данных за выбранный год',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.caption,
          ),
        ),
      );
    }
    if ((_detail?.semesters.isEmpty ?? true) && !_loading) {
      return Center(
        child: Text(
          'Нет данных о пропусках',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.caption,
          ),
        ),
      );
    }

    final yearKey = _selectedYearKey();
    final yearTotalStr = _yearTotalDisplay(yearKey);
    final yearExcusedStr = _yearExcusedDisplay(yearKey);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            child: _AbsencePeriodSelector(
              periodLabel: _yearPeriodLabel(),
              onPrev: _prevYear,
              onNext: _nextYear,
              onTap: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            // Фиксированная высота: IntrinsicHeight + Expanded в Row даёт неверные ограничения.
            child: SizedBox(
              height: 136,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0267FB),
                        borderRadius: BorderRadius.circular(26.4),
                        boxShadow: _shadowProfile,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26.4),
                        // Декоративный SVG — слой под текстом, не участвует в ширине текста (не Row).
                        child: Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              right: -6,
                              top: 0,
                              bottom: 0,
                              width: 96,
                              child: IgnorePointer(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SvgPicture.asset(
                                      'assets/icons/uspex.svg',
                                      width: constraints.maxWidth,
                                      height: constraints.maxHeight,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.centerRight,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0x1AFFFFFF),
                                        BlendMode.srcIn,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Пропуски',
                                    style: AppTextStyle.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      height: 1.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Общее количество пропущенных часов за год',
                                    style: AppTextStyle.inter(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 8.6,
                                      height: 1.15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      yearTotalStr,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyle.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 19,
                                        height: 1.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(26.4),
                        boxShadow: _shadowExcusedCard,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Пропуски',
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                height: 1.0,
                                color: _excusedCardText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'По уважительной причине',
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w400,
                                fontSize: 8.6,
                                height: 1.15,
                                color: _excusedCardText,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                yearExcusedStr,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 19,
                                  height: 1.0,
                                  color: _excusedCardText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ..._semesterBlocks(sems),
        ],
      ),
    );
  }

  /// Подписи семестров и чёрные карточки — все семестры выбранного года подряд.
  List<Widget> _semesterBlocks(List<AbsenceSemesterRow> sems) {
    final out = <Widget>[];
    for (var i = 0; i < sems.length; i++) {
      final row = sems[i];
      final caption = row.semester.trim();
      final label = _semesterDetailLabel(row);
      if (i > 0) {
        out.add(const SizedBox(height: 10));
      }
      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              caption.isEmpty ? '—' : caption,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12.59,
                height: 1.0,
                color: const Color(0xAB4B4B4B),
              ),
            ),
          ),
        ),
      );
      out.add(const SizedBox(height: 3));
      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _SemesterAbsencesCourseCard(absenceLabel: label),
        ),
      );
    }
    return out;
  }

  String _semesterDetailLabel(AbsenceSemesterRow row) {
    final a = row.totalAbsences;
    if (a != null) return _formatAbsencesRu(a);
    return _formatHoursRu(row.totalHours);
  }
}

class _AbsencesMainTab extends StatelessWidget {
  const _AbsencesMainTab({
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

const double _dateControlHeight = 30;

class _AbsencePeriodSelector extends StatelessWidget {
  const _AbsencePeriodSelector({
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

/// Как карточка «курс» в профиле: тёмный фон, «Пропуски» и счётчик семестра справа снизу.
class _SemesterAbsencesCourseCard extends StatelessWidget {
  const _SemesterAbsencesCourseCard({required this.absenceLabel});

  final String absenceLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(4, 5),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -8,
              top: 0,
              bottom: 0,
              child: SvgPicture.asset(
                'assets/icons/uspex.svg',
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                width: 120,
                colorFilter: const ColorFilter.mode(
                  Color(0x1AFFFFFF),
                  BlendMode.srcIn,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пропуски',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 17.54,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      absenceLabel,
                      textAlign: TextAlign.right,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.78,
                        height: 23.67 / 15.78,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Заголовок группы по дате — как [GradesListView] / `_DateGroup`.
class _AbsenceDateGroupHeader extends StatelessWidget {
  const _AbsenceDateGroupHeader({required this.date});

  /// `null` — блок «Без даты».
  final DateTime? date;

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];
  static const _weekdays = [
    'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье',
  ];

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    final first = s[0].toUpperCase();
    if (s.length == 1) return first;
    return '$first${s.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final d = date;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: d == null
          ? Text(
              'Без даты',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 19.47,
                height: 1.0,
                color: const Color(0xFF000000),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.day} ${_months[d.month - 1]}',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 19.47,
                    height: 1.0,
                    color: const Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _capitalizeFirst(_weekdays[d.weekday - 1]),
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.59,
                    height: 1.0,
                    color: const Color(0xAB4B4B4B),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AbsenceCurrentGradeCard extends StatelessWidget {
  const _AbsenceCurrentGradeCard({required this.row});

  final _MergedCurrentRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(97.3),
        color: const Color(0xFFFFFFFF),
        border: Border.all(
          color: const Color(0x24000000),
          width: 0.46,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            offset: Offset(1.39, 1.85),
            blurRadius: 6.39,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: AppUi.contentPaddingV,
      ),
      child: GradeItemTile(
        subjectName: row.subjectName,
        grade: row.grade,
        subtitle: row.subtitle,
        type: row.type,
        isSpecialType: row.isSpecialType,
      ),
    );
  }
}

class _MergedCurrentRow {
  const _MergedCurrentRow({
    required this.subjectName,
    required this.grade,
    required this.subtitle,
    this.type,
    this.isSpecialType = false,
    this.sortDate,
  });

  final String subjectName;
  final String grade;
  final String subtitle;
  final String? type;
  final bool isSpecialType;
  final DateTime? sortDate;
}
