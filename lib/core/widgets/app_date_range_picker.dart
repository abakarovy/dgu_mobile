import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_ui.dart';
import '../navigation/app_overlay_notifier.dart';
import '../theme/app_text_styles.dart';

/// Выбор диапазона дат: нижний лист в стиле приложения (не системный/OS picker).
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTimeRange initialDateRange,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final fd = DateTime(firstDate.year, firstDate.month, firstDate.day);
  final ld = DateTime(lastDate.year, lastDate.month, lastDate.day);
  var s = DateTime(
    initialDateRange.start.year,
    initialDateRange.start.month,
    initialDateRange.start.day,
  );
  var e = DateTime(
    initialDateRange.end.year,
    initialDateRange.end.month,
    initialDateRange.end.day,
  );
  if (s.isBefore(fd)) s = fd;
  if (e.isAfter(ld)) e = ld;
  if (e.isBefore(s)) {
    final t = s;
    s = e;
    e = t;
  }

  return AppOverlayNotifier.wrapModalBottomSheet(() {
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
        final maxH = MediaQuery.sizeOf(ctx).height * 0.92;
        final sheetH = MediaQuery.sizeOf(ctx).height - bottomInset;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: sheetH,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                // Под панелью: тап по «пустому» месту закрывает (как у шита оценок по предмету).
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH),
                    child: _AppDateRangePickerPanel(
                      firstDate: fd,
                      lastDate: ld,
                      initialStart: s,
                      initialEnd: e,
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

const _monthNamesRu = <String>[
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const _weekdayShortRu = <String>['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

class _AppDateRangePickerPanel extends StatefulWidget {
  const _AppDateRangePickerPanel({
    required this.firstDate,
    required this.lastDate,
    required this.initialStart,
    required this.initialEnd,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_AppDateRangePickerPanel> createState() =>
      _AppDateRangePickerPanelState();
}

class _AppDateRangePickerPanelState extends State<_AppDateRangePickerPanel> {
  late DateTime _visibleMonth;
  late DateTime _selStart;
  DateTime? _selEnd;

  @override
  void initState() {
    super.initState();
    _selStart = widget.initialStart;
    _selEnd = widget.initialEnd;
    _visibleMonth = DateTime(
      widget.initialStart.year,
      widget.initialStart.month,
    );
  }

  void _prevMonth() {
    final prev = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    if (prev.isBefore(firstMonth)) return;
    setState(() => _visibleMonth = prev);
  }

  void _nextMonth() {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    if (next.isAfter(lastMonth)) return;
    setState(() => _visibleMonth = next);
  }

  bool get _canPrev {
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    return DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
    ).isAfter(firstMonth);
  }

  bool get _canNext {
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    return DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
    ).isBefore(lastMonth);
  }

  void _onDayTap(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (d.isBefore(widget.firstDate) || d.isAfter(widget.lastDate)) return;

    setState(() {
      if (d.year != _visibleMonth.year || d.month != _visibleMonth.month) {
        _visibleMonth = DateTime(d.year, d.month);
      }
      if (_selEnd != null) {
        _selStart = d;
        _selEnd = null;
        return;
      }
      if (_selEnd == null) {
        final start = _selStart;
        if (d.isBefore(start)) {
          _selEnd = start;
          _selStart = d;
        } else if (d.isAfter(start)) {
          _selEnd = d;
        } else {
          _selEnd = d;
        }
      }
    });
  }

  void _confirm() {
    final start = _selStart;
    final end = _selEnd ?? _selStart;
    Navigator.of(context).pop(DateTimeRange(start: start, end: end));
  }

  (DateTime, DateTime) _orderedRange() {
    final a = _selStart;
    final b = _selEnd ?? _selStart;
    if (a.isAfter(b)) return (b, a);
    return (a, b);
  }

  @override
  Widget build(BuildContext context) {
    final (rangeStart, rangeEnd) = _orderedRange();

    return Material(
      color: AppColors.surfaceLight,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppUi.radiusXl)),
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppUi.screenPaddingH,
          12,
          AppUi.screenPaddingH,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
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
                  const SizedBox(height: 12),
                  Text(
                    'Выберите период',
                    textAlign: TextAlign.center,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      height: 22 / 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _canPrev ? _prevMonth : null,
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: _canPrev
                              ? AppColors.primaryBlue
                              : AppColors.lightGrey,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${_monthNamesRu[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _canNext ? _nextMonth : null,
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: _canNext
                              ? AppColors.primaryBlue
                              : AppColors.lightGrey,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final w in _weekdayShortRu)
                        Expanded(
                          child: Center(
                            child: Text(
                              w,
                              style: AppTextStyle.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: AppColors.caption,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MonthGrid(
                    visibleMonth: _visibleMonth,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    rangeStart: rangeStart,
                    rangeEnd: rangeEnd,
                    onDayTap: _onDayTap,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.lightGrey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppUi.radiusM,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Отмена',
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.onDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppUi.radiusM,
                              ),
                            ),
                          ),
                          onPressed: _confirm,
                          child: Text(
                            'Готово',
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.onDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.firstDate,
    required this.lastDate,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onDayTap,
  });

  final DateTime visibleMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final void Function(DateTime) onDayTap;

  static int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final y = visibleMonth.year;
    final m = visibleMonth.month;
    final dim = _daysInMonth(y, m);
    final first = DateTime(y, m, 1);
    final leading = first.weekday - DateTime.monday;
    final totalCells = leading + dim;
    final rows = (totalCells / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _buildCell(
                      row: row,
                      col: col,
                      leading: leading,
                      dim: dim,
                      y: y,
                      month: m,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell({
    required int row,
    required int col,
    required int leading,
    required int dim,
    required int y,
    required int month,
  }) {
    final idx = row * 7 + col;

    late DateTime day;
    late bool isOtherMonth;
    if (idx < leading) {
      final prevLast = DateTime(y, month, 0);
      final dimPrev = prevLast.day;
      final dayNum = dimPrev - (leading - 1 - idx);
      day = DateTime(prevLast.year, prevLast.month, dayNum);
      isOtherMonth = true;
    } else if (idx < leading + dim) {
      final dayNum = idx - leading + 1;
      day = DateTime(y, month, dayNum);
      isOtherMonth = false;
    } else {
      final t = idx - leading - dim + 1;
      day = DateTime(y, month + 1, t);
      isOtherMonth = true;
    }

    final dayNum = day.day;
    if (day.isBefore(firstDate) || day.isAfter(lastDate)) {
      return SizedBox(
        height: 40,
        child: Center(
          child: Text(
            '$dayNum',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.lightGrey,
            ),
          ),
        ),
      );
    }

    final inRange = !day.isBefore(rangeStart) && !day.isAfter(rangeEnd);
    final isStart =
        day.year == rangeStart.year &&
        day.month == rangeStart.month &&
        day.day == rangeStart.day;
    final isEnd =
        day.year == rangeEnd.year &&
        day.month == rangeEnd.month &&
        day.day == rangeEnd.day;
    final single = isStart && isEnd;

    /// Тот же оттенок, что у кнопки «Готово», в полупрозрачной заливке диапазона.
    final rangeFill = AppColors.primaryBlue.withValues(alpha: 0.18);

    Color? bg;
    BorderRadius? radius;
    if (inRange) {
      if (single) {
        radius = BorderRadius.circular(20);
        bg = AppColors.primaryBlue;
      } else {
        bg = rangeFill;
        if (isStart) {
          radius = const BorderRadius.horizontal(left: Radius.circular(20));
        } else if (isEnd) {
          radius = const BorderRadius.horizontal(right: Radius.circular(20));
        }
      }
    }

    // Соседние месяцы в сетке — цифры чуть приглушённее текущего месяца.
    final Color textColor;
    if (single) {
      textColor = AppColors.onDark;
    } else if (isStart || isEnd) {
      textColor = AppColors.primaryBlue;
    } else if (isOtherMonth) {
      textColor = inRange ? AppColors.notificationSubtitle : AppColors.caption;
    } else {
      textColor = AppColors.textPrimary;
    }

    final fontWeight = FontWeight.w600;

    return SizedBox(
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDayTap(day),
          borderRadius: BorderRadius.circular(20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
            ),
            child: Center(
              child: Text(
                '$dayNum',
                style: AppTextStyle.inter(
                  fontWeight: fontWeight,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
