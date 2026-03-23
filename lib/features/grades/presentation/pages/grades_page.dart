import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../widgets/grades_list_view.dart';

/// Вкладка «Оценки»: 3 таба (Текущие, Сессия, Итого).
/// Текущие: выбор периода (неделя по умолчанию), стрелки, календарь; оценки с датами и типами.
class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> with SingleTickerProviderStateMixin {
  static const List<String> _tabLabels = ['Текущие', 'Сессия', 'Итого'];

  late TabController _tabController;
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now();
  bool _isWeekMode = true;

  static final List<GradeListItem> _currentGrades = [
    GradeListItem(
      subjectName: 'Веб разработка',
      grade: '5',
      subtitle: 'Алиева А.М.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: 'Опрос',
    ),
    GradeListItem(
      subjectName: 'Базы данных',
      grade: '4',
      subtitle: 'Иванов И.И.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: 'Введение тетради',
    ),
    GradeListItem(
      subjectName: 'Математика',
      grade: '5',
      subtitle: 'Петрова П.П.',
      date: DateTime.now(),
      type: 'Контрольная работа',
    ),
    GradeListItem(
      subjectName: 'Физика',
      grade: '3',
      subtitle: 'Сидоров С.С.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: 'Промежуточная аттестация',
    ),
  ];

  static final List<GradeListItem> _semesterGrades = const [
    GradeListItem(
      subjectName: 'Веб разработка',
      grade: '5',
      subtitle: 'Зачёт, 20.01.2025',
    ),
    GradeListItem(
      subjectName: 'Базы данных',
      grade: '4',
      subtitle: 'Экзамен, 22.01.2025',
    ),
  ];

  static final List<GradeListItem> _totalGrades = const [
    GradeListItem(
      subjectName: 'Веб разработка',
      grade: '4.75',
      subtitle: 'средний балл',
    ),
    GradeListItem(
      subjectName: 'Базы данных',
      grade: '4.50',
      subtitle: 'средний балл',
    ),
    GradeListItem(
      subjectName: 'Математика',
      grade: '4.33',
      subtitle: 'средний балл',
    ),
    GradeListItem(
      subjectName: 'Физика',
      grade: '3.80',
      subtitle: 'средний балл',
    ),
    GradeListItem(
      subjectName: 'Иностранный язык',
      grade: '5.00',
      subtitle: 'средний балл',
    ),
  ];

  List<GradeListItem> get _filteredCurrentGrades {
    final start = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    final end = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day).add(const Duration(days: 1));
    return _currentGrades.where((e) {
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

  void _goToToday() {
    setState(() {
      _rangeStart = DateTime.now();
      _rangeEnd = DateTime.now();
      _isWeekMode = false;
    });
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
    final picked = await showDateRangePicker(
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    final weekday = now.weekday;
    final mondayOffset = weekday == 7 ? 6 : weekday - 1;
    _rangeStart = now.subtract(Duration(days: mondayOffset));
    _rangeEnd = _rangeStart.add(const Duration(days: 6));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppUi.screenPaddingH, 8, AppUi.screenPaddingH, 12),
          child: ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(10),
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
                  if (idx == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppUi.screenPaddingH, 0, AppUi.screenPaddingH, 12),
                      child: Row(
                        children: [
                          _TodayButton(onTap: _goToToday),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PeriodSelector(
                              periodLabel: _periodLabel,
                              onPrev: _prevPeriod,
                              onNext: _nextPeriod,
                              onTap: () => _showDatePickerSheet(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCurrentTab(),
                        GradesListView(items: _semesterGrades),
                        GradesListView(items: _totalGrades),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        ],
    );
  }

  Widget _buildCurrentTab() {
    return GradesListView(
      items: _filteredCurrentGrades,
      groupByDate: true,
    );
  }
}

const double _dateControlHeight = 36;

class _TodayButton extends StatelessWidget {
  const _TodayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _dateControlHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Text('Сегодня', style: AppTextStyle.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            )),
          ),
        ),
      ),
    );
  }
}

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
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
        children: [
          GestureDetector(
            onTap: onPrev,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.chevron_left, size: 18, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Text(
                  periodLabel,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onNext,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.chevron_right, size: 18, color: AppColors.textPrimary),
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
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        splashColor: AppColors.surfaceLight,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyle.inter(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
                height: 1.0,
                color: selected ? AppColors.primaryBlue : AppColors.caption,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
