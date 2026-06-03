import 'dart:async';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/widgets/app_date_range_picker.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/navigation/app_overlay_notifier.dart';
import 'package:dgu_mobile/core/utils/calendar_period.dart';
import 'package:dgu_mobile/core/utils/parent_child_name.dart';
import 'package:flutter/material.dart';

import '../models/session_grade_breakdown.dart';
import '../widgets/grade_item_tile.dart';
import '../widgets/grades_list_view.dart';
import '../widgets/learning_route_view.dart';
import '../widgets/subject_grades_sheet.dart';
import '../../domain/entities/grade_entity.dart';
import '../../domain/grade_type_labels.dart';
import '../../domain/merge_journal_absence_rows.dart';

/// Вкладка «Оценки»: 3 таба (Текущие, Сессия, Учебный маршрут).
/// Сессия: оценки за сессию (аттестации, зачёты и т.п.), переключатель семестров из 1С.
class GradesPage extends StatefulWidget {
  const GradesPage({
    super.key,
    this.initialTabIndex = 0,
    this.focusGradeDate,
  });

  /// 0 — «Текущие», 1 — «Сессия», 2 — «Маршрут».
  final int initialTabIndex;

  /// Из push / deep link: сузить «Текущие» до этого календарного дня и показать подсказку.
  final DateTime? focusGradeDate;

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
  static const String _cacheKeySemesters = 'grades:semesters';

  List<GradeEntity> _grades = const <GradeEntity>[];
  /// Порядок семестров из ответа `sync-grades` (пусто — берём из записей).
  List<String> _semesterOrder = const <String>[];
  bool _refreshing = false;
  int _sessionSemesterIndex = 0;
  bool _sessionSemesterIndexInitialized = false;

  /// Типы итогов сессии (аттестации, зачёты, экзамены и т.п.). Контрольные, к/р — во «Текущие», не сюда.
  static bool _isSessionType(String? t) =>
      GradeTypeLabels.isSessionOutcome((t ?? '').trim());

  /// Оценка для вкладки «Сессия»: только если в API есть значение.
  static String? _sessionGradeValue(String raw) {
    final g = raw.trim();
    if (g.isEmpty || g == '-' || g == '—') return null;
    return g;
  }

  /// В журнале с бэка часто приходят строки без оценки (grade_value: null) — для «Текущие» их не показываем,
  /// иначе справа остаётся пустой цветной квадрат.
  static bool _hasGradeValue(GradeEntity g) => g.grade.trim().isNotEmpty;

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
    final a = CalendarPeriod.dateOnly(_rangeStart);
    final b = CalendarPeriod.dateOnly(_rangeEnd);
    if (a == b) {
      return CalendarPeriod.formatDdMmYyyy(a);
    }
    return '${CalendarPeriod.formatDdMmYyyy(a)} — ${CalendarPeriod.formatDdMmYyyy(b)}';
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
    final picked = await showAppDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
    );
    if (picked != null && mounted) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
        _isWeekMode = CalendarPeriod.inclusiveDays(picked.start, picked.end) == 7;
      });
    }
  }

  Future<void> _showDatePickerSheet(BuildContext context) async {
    await _pickDateRange(context);
  }

  void _showSubjectGrades(
    BuildContext context,
    String subjectName, {
    required bool sessionTab,
  }) {
    final grades =
        sessionTab ? _itemsForSessionSubject(subjectName) : _itemsForCurrentSubject(subjectName);
    if (context.mounted) {
      showSubjectGradesSheet(context, subjectName: subjectName, grades: grades);
    }
  }

  /// Оценки предмета для шита: только «Текущие» (не итоги сессии), все загруженные строки.
  List<GradeListItem> _itemsForCurrentSubject(String name) {
    return mergeJournalAbsenceRows(
      _grades
          .where((g) => g.subjectName == name)
          .where((g) => !_isSessionType(g.gradeType))
          .where(_hasGradeValue)
          .toList(),
    ).map(_toListItem).toList();
  }

  /// Оценки предмета для шита на вкладке «Сессия» (итоги за выбранный семестр).
  List<GradeListItem> _itemsForSessionSubject(String name) {
    final semesters = _effectiveSemesters();
    if (semesters.isEmpty) return [];
    final idx = _sessionSemesterIndex.clamp(0, semesters.length - 1);
    final selected = semesters[idx];
    return _grades
        .where((g) => (g.semester ?? '').trim() == selected)
        .where((g) => g.subjectName == name)
        .where((g) => _isSessionType(g.gradeType))
        .map(_toListItem)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final initialIdx = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIdx);
    final week = CalendarPeriod.weekMonSunContaining(DateTime.now());
    _rangeStart = week.start;
    _rangeEnd = week.end;
    _isWeekMode = true;

    final focus = widget.focusGradeDate;
    if (focus != null) {
      final d = CalendarPeriod.dateOnly(focus);
      _rangeStart = d;
      _rangeEnd = d;
      _isWeekMode = false;
    }

    _grades = _decodeCachedGrades();
    _semesterOrder = _decodeCachedSemesters();
    _clampSemesterIndex();
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
        if (widget.focusGradeDate != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Material(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 20, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Из уведомления: оценки за ${CalendarPeriod.formatDdMmYyyy(widget.focusGradeDate!)}',
                        style: AppTextStyle.inter(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                  if (idx == 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                      child: _PeriodSelector(
                        periodLabel: _sessionSemesterLabel(),
                        onPrev: _prevSessionSemester,
                        onNext: _nextSessionSemester,
                        onTap: () => _showSessionSemesterPicker(context),
                        canGoPrev: _canGoPrevSessionSemester(),
                        canGoNext: _canGoNextSessionSemester(),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCurrentTab(context),
                        _buildSessionTab(context),
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
    final currentEntities = mergeJournalAbsenceRows(
      _grades
          .where((g) => !_isSessionType(g.gradeType))
          .where(_hasGradeValue)
          .toList(),
    );
    final list = currentEntities.map(_toListItem).toList();
    final filtered = _filtered(list);

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
      onSubjectTap: (name) => _showSubjectGrades(context, name, sessionTab: false),
    );
  }

  /// Семестры: от нового к старому (как в `sync-grades` и в выборе семестра).
  List<String> _effectiveSemesters() {
    final raw = _semesterOrder.isNotEmpty
        ? List<String>.from(_semesterOrder)
        : _uniqueSemesters(_grades);
    raw.sort(_compareSemestersNewestFirst);
    return raw;
  }

  /// Ключ для сортировки: «2 сем 2025-2026» → 20252 (год начала × 10 + номер семестра).
  static int? _semesterSortKey(String raw) {
    final t = raw.trim().toLowerCase().replaceAll('семестр', 'сем');
    final m = RegExp(
      r'^(\d+)\s*(?:сем|sem)\.?\s+(\d{4})\s*-\s*(\d{4})',
      caseSensitive: false,
    ).firstMatch(t);
    if (m == null) return null;
    final semNum = int.tryParse(m.group(1)!);
    final yearStart = int.tryParse(m.group(2)!);
    if (semNum == null || yearStart == null) return null;
    return yearStart * 10 + semNum;
  }

  static int _compareSemestersNewestFirst(String a, String b) {
    final ka = _semesterSortKey(a);
    final kb = _semesterSortKey(b);
    if (ka != null && kb != null) return kb.compareTo(ka);
    if (ka != null) return -1;
    if (kb != null) return 1;
    return b.compareTo(a);
  }

  void _clampSemesterIndex() {
    final sems = _effectiveSemesters();
    if (sems.isEmpty) {
      _sessionSemesterIndex = 0;
      _sessionSemesterIndexInitialized = false;
      return;
    }
    if (!_sessionSemesterIndexInitialized) {
      // Индекс 0 — самый новый семестр после сортировки.
      _sessionSemesterIndex = 0;
      _sessionSemesterIndexInitialized = true;
    } else if (_sessionSemesterIndex >= sems.length) {
      _sessionSemesterIndex = 0;
    }
  }

  /// Стрелка влево — на один семестр «назад» по времени (старее).
  bool _canGoPrevSessionSemester() {
    final n = _effectiveSemesters().length;
    if (n <= 1) return false;
    return _sessionSemesterIndex < n - 1;
  }

  /// Стрелка вправо — на один семестр «вперёд» по времени (новее).
  bool _canGoNextSessionSemester() {
    final n = _effectiveSemesters().length;
    if (n <= 1) return false;
    return _sessionSemesterIndex > 0;
  }

  List<String> _uniqueSemesters(List<GradeEntity> items) {
    final set = <String>{};
    for (final g in items) {
      final s = (g.semester ?? '').trim();
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Итоги сессии по дисциплинам (атт., зачёт, экзамен и т.д.), не журнал «по дням» как в «Текущие».
  Widget _buildSessionTab(BuildContext context) {
    if (_grades.isEmpty && _refreshing) {
      return const Center(child: CircularProgressIndicator());
    }
    final semesters = _effectiveSemesters();
    if (semesters.isEmpty) {
      return Center(
        child: Text(
          'Нет семестров в данных',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.caption),
        ),
      );
    }
    final n = semesters.length;
    final idx = _sessionSemesterIndex.clamp(0, n - 1);
    final selected = semesters[idx];
    final semesterEntities = _grades
        .where((g) => (g.semester ?? '').trim() == selected)
        .where((g) => _isSessionType(g.gradeType))
        .toList();
    if (semesterEntities.isEmpty) {
      return Center(
        child: Text(
          'Нет оценок за сессию',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.caption),
        ),
      );
    }

    final bySubject = <String, List<GradeEntity>>{};
    for (final g in semesterEntities) {
      bySubject.putIfAbsent(g.subjectName, () => []).add(g);
    }
    final subjects = bySubject.keys.toList()..sort();
    final visibleSubjects = <String>[
      for (final name in subjects)
        if (_sessionSubjectHasVisibleOutcomes(bySubject[name]!)) name,
    ];

    if (visibleSubjects.isEmpty) {
      return Center(
        child: Text(
          'Нет итогов за сессию',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.caption),
        ),
      );
    }

    const sessionCardSpacing = 16.0;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, sessionCardSpacing),
      itemCount: visibleSubjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: sessionCardSpacing),
      itemBuilder: (context, i) {
        final name = visibleSubjects[i];
        final list = bySubject[name]!;
        final breakdown = _breakdownFor(list);
        final extraForms = _extraSessionForms(list, breakdown);
        final teacher = _pickAnyTeacher(list);
        return _SessionGradeCard(
          subjectName: name,
          teacherName: teacher,
          breakdown: breakdown,
          extraForms: extraForms,
          onTap: () => _showSubjectGrades(context, name, sessionTab: true),
        );
      },
    );
  }

  bool _sessionSubjectHasVisibleOutcomes(List<GradeEntity> grades) {
    final breakdown = _breakdownFor(grades);
    if (breakdown.att1 != null ||
        breakdown.att2 != null ||
        _SessionGradeCard.hasSessionForms(breakdown)) {
      return true;
    }
    return _extraSessionForms(grades, breakdown).isNotEmpty;
  }

  String? _sessionOutcomeSlot(String typeRaw) =>
      GradeTypeLabels.sessionSlot(typeRaw);

  Set<String> _coveredSessionSlots(SessionGradeBreakdown b) {
    final slots = <String>{};
    if (b.att1 != null) slots.add('att1');
    if (b.att2 != null) slots.add('att2');
    if (b.dfk != null) slots.add('dfk');
    if (b.kurs != null) slots.add('kurs');
    if (b.ekz != null) slots.add('ekz');
    if (b.zach != null) slots.add('zach');
    return slots;
  }

  List<({String label, String value})> _extraSessionForms(
    List<GradeEntity> grades,
    SessionGradeBreakdown breakdown,
  ) {
    final covered = _coveredSessionSlots(breakdown);
    final out = <({String label, String value})>[];
    final sorted = List<GradeEntity>.from(grades)
      ..sort(
        (a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)),
      );
    for (final g in sorted) {
      final typeRaw = (g.gradeType ?? '').trim();
      if (!_isSessionType(typeRaw)) continue;
      final slot = _sessionOutcomeSlot(typeRaw);
      if (slot == null || slot.startsWith('att')) continue;
      if (covered.contains(slot)) continue;
      final value = _sessionGradeValue(g.grade);
      if (value == null) continue;
      covered.add(slot);
      out.add((
        label: GradeTypeLabels.displayLabel(typeRaw),
        value: value,
      ));
    }
    return out;
  }

  SessionGradeBreakdown _breakdownFor(List<GradeEntity> grades) {
    final sorted = List<GradeEntity>.from(grades)
      ..sort(
        (a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)),
      );

    String? pickForSlot(String slot) {
      for (final g in sorted) {
        final t = g.gradeType ?? '';
        if (!GradeTypeLabels.matchesSlot(t, slot)) continue;
        final v = _sessionGradeValue(g.grade);
        if (v != null) return v;
      }
      return null;
    }


    return SessionGradeBreakdown(
      att1: pickForSlot('att1'),
      att2: pickForSlot('att2'),
      dfk: pickForSlot('dfk'),
      kurs: pickForSlot('kurs'),
      zach: pickForSlot('zach'),
      ekz: pickForSlot('ekz'),
    );
  }

  String _pickAnyTeacher(List<GradeEntity> grades) {
    for (final g in grades) {
      final t = (g.teacherName ?? '').trim();
      if (t.isEmpty) continue;
      if (_looksLikeGradeType(t)) continue;
      return _shortTeacherName(t);
    }
    return '';
  }

  bool _looksLikeGradeType(String raw) {
    final s = raw.toLowerCase();
    return s.contains('экзам') ||
        s.contains('зач') ||
        s.contains('дифф') ||
        s.contains('аттест') ||
        s.contains('пропуск') ||
        s.contains('контроль') ||
        s.contains('балль');
  }

  String _shortTeacherName(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    final parts = s
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '';
    final surname = parts[0];
    String initialAt(int i) {
      if (parts.length <= i) return '';
      final p = parts[i].replaceAll('.', '');
      if (p.isEmpty) return '';
      return p.isNotEmpty ? p.substring(0, 1).toUpperCase() : '';
    }

    final i1 = initialAt(1);
    final i2 = initialAt(2);
    if (i1.isEmpty && i2.isEmpty) return surname;
    final buf = StringBuffer()..write(surname);
    if (i1.isNotEmpty) buf.write(' $i1.');
    if (i2.isNotEmpty) buf.write('$i2.');
    return buf.toString();
  }

  String _sessionSemesterLabel() {
    final semesters = _effectiveSemesters();
    if (semesters.isEmpty) return 'Семестр';
    final n = semesters.length;
    final i = _sessionSemesterIndex.clamp(0, n - 1);
    return semesters[i];
  }

  /// Строки для списка: «N семестр» + учебный год, если распознан формат 1С.
  (String title, String? yearPart) _sessionPickerLines(String raw) {
    final t = raw.trim();
    final m = RegExp(r'^(\d+)\s*сем\.?\s+(.+)$', caseSensitive: false)
        .firstMatch(t);
    if (m != null) {
      final num = m.group(1)!;
      final rest = m.group(2)!.trim();
      return ('$num семестр', rest.isEmpty ? null : rest);
    }
    return (t, null);
  }

  Future<void> _showSessionSemesterPicker(BuildContext context) async {
    final semesters = _effectiveSemesters();
    if (semesters.isEmpty) return;
    final currentIdx = _sessionSemesterIndex.clamp(0, semesters.length - 1);

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
          final sheetH = MediaQuery.sizeOf(ctx).height - bottomInset;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SizedBox(
              height: sheetH,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: maxH,
                      width: double.infinity,
                      child: Material(
                        color: AppColors.surfaceLight,
                        clipBehavior: Clip.antiAlias,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppUi.radiusXl),
                          ),
                        ),
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
                                      'Семестр и учебный год',
                                      style: AppTextStyle.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        height: 1.2,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppColors.caption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 24),
                                itemCount: semesters.length,
                                separatorBuilder: (context, _) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, i) {
                                  final label = semesters[i];
                                  final (title, yearPart) =
                                      _sessionPickerLines(label);
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
                                          _sessionSemesterIndex = i;
                                          _sessionSemesterIndexInitialized = true;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: AppTextStyle.inter(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                      height: 1.2,
                                                      color: AppColors
                                                          .textPrimary,
                                                    ),
                                                  ),
                                                  if (yearPart != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      yearPart,
                                                      style:
                                                          AppTextStyle.inter(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 13,
                                                        height: 1.25,
                                                        color: AppColors
                                                            .notificationSubtitle,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (selected)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                size: 22,
                                                color: Color(0xFF2563EB),
                                              ),
                                          ],
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
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _prevSessionSemester() {
    if (!_canGoPrevSessionSemester()) return;
    setState(() => _sessionSemesterIndex += 1);
  }

  void _nextSessionSemester() {
    if (!_canGoNextSessionSemester()) return;
    setState(() => _sessionSemesterIndex -= 1);
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

  List<String> _decodeCachedSemesters() {
    final cached = AppContainer.jsonCache.getJsonList(_cacheKeySemesters);
    if (cached == null) return const <String>[];
    return cached
        .map((e) => e is String ? e : (e == null ? '' : '$e'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _refreshGrades() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      int? sid;
      if (ParentChildName.isParentRole()) {
        sid = await ParentChildName.ensureChildStudentIdLoaded();
        if (sid == null) {
          if (mounted) setState(() => _refreshing = false);
          return;
        }
      }
      final bundle = await AppContainer.gradesApi.loadMyGrades(studentIdOverride: sid);
      final cached = _decodeCachedGrades();
      final cachedSems = _decodeCachedSemesters();
      final fresh = bundle.grades;
      final freshSems = bundle.semesters;
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
        await AppContainer.jsonCache.setJson(_cacheKeySemesters, freshSems);
        if (mounted) {
          setState(() {
            _grades = fresh;
            _semesterOrder = freshSems;
            _clampSemesterIndex();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _grades = cached;
            _semesterOrder = cachedSems;
            _clampSemesterIndex();
          });
        }
      }
    } catch (_) {
      final cached = _decodeCachedGrades();
      final cachedSems = _decodeCachedSemesters();
      if (mounted && cached.isNotEmpty) {
        setState(() {
          _grades = cached;
          _semesterOrder = cachedSems;
          _clampSemesterIndex();
        });
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}

class _SessionGradeCard extends StatelessWidget {
  const _SessionGradeCard({
    required this.subjectName,
    required this.teacherName,
    required this.breakdown,
    this.extraForms = const [],
    required this.onTap,
  });

  final String subjectName;
  final String teacherName;
  final SessionGradeBreakdown breakdown;
  final List<({String label, String value})> extraForms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subjectName,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.0,
                color: const Color(0xFF000000),
              ),
            ),
            if (teacherName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                teacherName,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 1.2,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
            if (breakdown.att1 != null || breakdown.att2 != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (breakdown.att1 != null)
                    Expanded(child: _attChip('1', value: breakdown.att1!)),
                  if (breakdown.att1 != null && breakdown.att2 != null)
                    const SizedBox(width: 6),
                  if (breakdown.att2 != null)
                    Expanded(child: _attChip('2', value: breakdown.att2!)),
                ],
              ),
            ],
            if (_SessionGradeCard.hasSessionForms(breakdown) ||
                extraForms.isNotEmpty) ...[
              SizedBox(height: breakdown.att1 != null || breakdown.att2 != null ? 6 : 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if ((breakdown.ekz ?? '').trim().isNotEmpty)
                    _gradeChip('Экзамен', breakdown.ekz!.trim()),
                  if ((breakdown.zach ?? '').trim().isNotEmpty)
                    _gradeChip('Зачёт', breakdown.zach!.trim()),
                  if ((breakdown.dfk ?? '').trim().isNotEmpty)
                    _gradeChip('Диф. зачёт', breakdown.dfk!.trim()),
                  if ((breakdown.kurs ?? '').trim().isNotEmpty)
                    _gradeChip('Курсовая', breakdown.kurs!.trim()),
                  for (final f in extraForms)
                    _gradeChip(f.label, f.value),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static bool _hasChipValue(String? v) {
    final t = (v ?? '').trim();
    return t.isNotEmpty && t != '-' && t != '—';
  }

  static bool hasSessionForms(SessionGradeBreakdown b) =>
      _hasChipValue(b.ekz) ||
      _hasChipValue(b.zach) ||
      _hasChipValue(b.dfk) ||
      _hasChipValue(b.kurs);

  Widget _attChip(String n, {required String value}) {
    const bg = Color(0x242563EB);
    const border = Color(0xFF2563EB);
    const text = Color(0xFF2563EB);
    final label = 'Аттестация $n · $value';
    return _pill(label, bg: bg, border: border, textColor: text);
  }

  Widget _gradeChip(String label, String rawValue) {
    final shown = '$label · ${rawValue.trim()}';
    final (text, bg, border) = _colorsForValue(rawValue);
    return _pill(shown, bg: bg, border: border, textColor: text);
  }

  (Color text, Color bg, Color border) _colorsForValue(String raw) {
    return GradeItemTile.colorsForGradeChip(raw);
  }

  Widget _pill(
    String label, {
    required Color bg,
    required Color border,
    required Color textColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 3,
          softWrap: true,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            height: 1.2,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

const double _dateControlHeight = 30;

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periodLabel,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
    this.canGoPrev = true,
    this.canGoNext = true,
  });

  final String periodLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;
  final bool canGoPrev;
  final bool canGoNext;

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
            SizedBox(
              width: 26,
              child: canGoPrev
                  ? GestureDetector(
                      onTap: onPrev,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.chevron_left, size: 18, color: Colors.white),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Text(
                    periodLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    softWrap: true,
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
            SizedBox(
              width: 26,
              child: canGoNext
                  ? GestureDetector(
                      onTap: onNext,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.chevron_right, size: 18, color: Colors.white),
                      ),
                    )
                  : null,
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
