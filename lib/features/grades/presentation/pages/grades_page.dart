import 'dart:async';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/platform/native_date_range_picker.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/utils/parent_child_name.dart';
import 'package:flutter/material.dart';

import '../models/session_grade_breakdown.dart';
import '../widgets/grades_list_view.dart';
import '../widgets/learning_route_view.dart';
import '../widgets/subject_grades_sheet.dart';
import '../../../grades/domain/entities/grade_entity.dart';

/// Вкладка «Оценки»: 3 таба (Текущие, Сессия, Учебный маршрут).
/// Сессия: оценки за сессию (аттестации, зачёты и т.п.), переключатель семестров из 1С.
class GradesPage extends StatefulWidget {
  const GradesPage({super.key, this.initialTabIndex = 0});

  /// 0 — «Текущие», 1 — «Сессия», 2 — «Маршрут».
  final int initialTabIndex;

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

  /// Типы итогов сессии (аттестации, зачёты, экзамены и т.п.). Контрольные, к/р — во «Текущие», не сюда.
  static bool _isSessionType(String? t) {
    final raw = (t ?? '').trim();
    if (raw.isEmpty) return false;
    final s = raw.toLowerCase();
    if (s.contains('ответ у доски')) return false;
    if (s.contains('пропуск')) return false;
    if (s.contains('контрольная')) return false;
    if (s.contains('к/р')) return false;
    // В ответах 1С встречаются "Юрайт", "Практика", "Опрос терминов", "1 АТ"/"2 АТ" —
    // это текущие активности/аттестации, а не "сессия" в смысле зачётов/экзаменов.
    // Поэтому здесь оставляем только явные итоги: зачёт/экзамен/дифф.зачёт/курсовая/итоговая аттестация.
    return s.contains('экзам') ||
        s.contains('зач') ||
        s.contains('дифф') ||
        s.contains('курсов') ||
        s.contains('итог') ||
        s.contains('гэк') ||
        s.contains('гос');
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
    final initialIdx = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIdx);
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    // Последние 14 дней (включая сегодня): одной календарной недели часто мало,
    // оценки из журнала 1С за прошлую неделю иначе не попадают в «Текущие».
    _rangeEnd = day;
    _rangeStart = day.subtract(const Duration(days: 13));

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
                        onTap: () {},
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

  /// Семестры как в ответе 1С, иначе уникальные из загруженных оценок.
  List<String> _effectiveSemesters() {
    if (_semesterOrder.isNotEmpty) return _semesterOrder;
    return _uniqueSemesters(_grades);
  }

  void _clampSemesterIndex() {
    final sems = _effectiveSemesters();
    if (sems.isEmpty) {
      _sessionSemesterIndex = 0;
      return;
    }
    if (_sessionSemesterIndex >= sems.length) _sessionSemesterIndex = 0;
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
    final allItems = semesterEntities.map(_toListItem).toList();
    _lastBySubject = _groupBySubject(allItems);

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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: subjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final name = subjects[i];
        final list = bySubject[name]!;
        final breakdown = _breakdownFor(list);
        final teacher = _pickAnyTeacher(list);
        return _SessionGradeCard(
          subjectName: name,
          teacherName: teacher,
          breakdown: breakdown,
          onTap: () => _showSubjectGrades(context, name),
        );
      },
    );
  }

  SessionGradeBreakdown _breakdownFor(List<GradeEntity> grades) {
    String? pick(bool Function(String s) p) {
      for (final g in grades) {
        final t = (g.gradeType ?? '').toLowerCase();
        if (p(t)) return g.grade;
      }
      return null;
    }

    bool hasAtt1(String s) =>
        s.contains('аттестация 1') ||
        s.contains('атт 1') ||
        (s.contains('1 ат') && !s.contains('ответ'));
    bool hasAtt2(String s) =>
        s.contains('аттестация 2') || s.contains('атт 2') || s.contains('2 ат');

    return SessionGradeBreakdown(
      att1: pick((s) => hasAtt1(s)) != null ? 'атт' : null,
      att2: pick((s) => hasAtt2(s)) != null ? 'атт' : null,
      dfk: pick((s) => s.contains('дифф')),
      kurs: pick((s) => s.contains('курсов')),
      zach: pick(
        (s) =>
            s.contains('зач') &&
            !s.contains('незач') &&
            !s.contains('дифф') &&
            !s.contains('дифференц'),
      ),
      ekz: pick((s) => s.contains('экзам')),
    );
  }

  String _pickAnyTeacher(List<GradeEntity> grades) {
    for (final g in grades) {
      final t = (g.teacherName ?? '').trim();
      if (t.isNotEmpty) return _shortTeacherName(t);
    }
    return '';
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

  void _prevSessionSemester() {
    final semesters = _effectiveSemesters();
    if (semesters.isEmpty) return;
    setState(() {
      final n = semesters.length;
      final i = _sessionSemesterIndex.clamp(0, n - 1);
      _sessionSemesterIndex = (i - 1 + n) % n;
    });
  }

  void _nextSessionSemester() {
    final semesters = _effectiveSemesters();
    if (semesters.isEmpty) return;
    setState(() {
      final n = semesters.length;
      final i = _sessionSemesterIndex.clamp(0, n - 1);
      _sessionSemesterIndex = (i + 1) % n;
    });
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
    required this.onTap,
  });

  final String subjectName;
  final String teacherName;
  final SessionGradeBreakdown breakdown;
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _attChip('1', isAtt: breakdown.att1 != null)),
                const SizedBox(width: 6),
                Expanded(child: _attChip('2', isAtt: breakdown.att2 != null)),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if ((breakdown.ekz ?? '').trim().isNotEmpty)
                  _gradeChip('Экз', breakdown.ekz!.trim()),
                if ((breakdown.zach ?? '').trim().isNotEmpty)
                  _gradeChip('Зачёт', breakdown.zach!.trim()),
                if ((breakdown.dfk ?? '').trim().isNotEmpty)
                  _gradeChip('Диф.зачёт', breakdown.dfk!.trim()),
                if ((breakdown.kurs ?? '').trim().isNotEmpty)
                  _gradeChip('Кур.', breakdown.kurs!.trim()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attChip(String n, {required bool isAtt}) {
    final bg = isAtt ? const Color(0x242563EB) : const Color(0x17C84547);
    final border = isAtt ? const Color(0xFF2563EB) : const Color(0xFFC84547);
    final text = isAtt ? const Color(0xFF2563EB) : const Color(0xFFC84547);
    final label = isAtt ? 'Атт $n' : 'неАтт $n';
    return _pill(label, bg: bg, border: border, textColor: text);
  }

  Widget _gradeChip(String kind, String rawValue) {
    final abbr = _abbrValue(rawValue);
    final shown = '$kind • $abbr';
    final (text, bg, border) = _colorsForValue(rawValue);
    return _pill(shown, bg: bg, border: border, textColor: text);
  }

  String _abbrValue(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '—';
    final lower = t.toLowerCase();
    if (RegExp(r'^[1-5]$').hasMatch(t)) {
      return switch (t) {
        '5' => 'отл',
        '4' => 'хор',
        '3' => 'удовл',
        _ => 'неуд',
      };
    }
    if (lower.contains('отл')) return 'отл';
    if (lower.contains('хор')) return 'хор';
    if (lower.contains('удов')) return 'удовл';
    if (lower.contains('неуд')) return 'неуд';
    if (lower.contains('зач')) return 'зач';
    if (lower.contains('незач')) return 'незач';
    return t;
  }

  (Color text, Color bg, Color border) _colorsForValue(String raw) {
    final t = raw.trim();
    final lower = t.toLowerCase();
    final code = RegExp(r'^[1-5]$').hasMatch(t)
        ? t
        : (lower.contains('отл') || lower.contains('зач'))
            ? '5'
            : (lower.contains('хор'))
                ? '4'
                : (lower.contains('удов'))
                    ? '3'
                    : (lower.contains('неуд') || lower.contains('незач'))
                        ? '2'
                        : null;
    if (code == '5') {
      return (const Color(0xFF10B981), const Color(0x1C10B981), const Color(0xFF10B981));
    }
    if (code == '4') {
      return (const Color(0xFFDF9D3F), const Color(0x2BFFD900), const Color(0xFFDF9D3F));
    }
    if (code == '3') {
      return (const Color(0xFF3B82F6), const Color(0x1C3B82F6), const Color(0xFF3B82F6));
    }
    if (code == '2' || code == '1') {
      return (const Color(0xFFC84547), const Color(0x17C84547), const Color(0xFFC84547));
    }
    return (const Color(0xFF64748B), const Color(0x1464748B), const Color(0xFF64748B));
  }

  Widget _pill(
    String label, {
    required Color bg,
    required Color border,
    required Color textColor,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 8.69,
            height: 1.0,
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
