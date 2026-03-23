import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import 'grade_item_tile.dart';
import 'grades_list_view.dart';

/// Bottom sheet с детализацией оценок по предмету: средний балл и список оценок (дата, тип, оценка).
void showSubjectGradesSheet(BuildContext context, {
  required String subjectName,
  required List<GradeListItem> grades,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: true,
    useRootNavigator: true,
    barrierColor: Colors.black54,
    builder: (context) => Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: false,
        child: _SubjectGradesSheet(
          subjectName: subjectName,
          grades: grades,
        ),
      ),
    ),
  );
}

class _SubjectGradesSheet extends StatefulWidget {
  const _SubjectGradesSheet({
    required this.subjectName,
    required this.grades,
  });

  final String subjectName;
  final List<GradeListItem> grades;

  @override
  State<_SubjectGradesSheet> createState() => _SubjectGradesSheetState();
}

class _SubjectGradesSheetState extends State<_SubjectGradesSheet> {
  final ValueNotifier<double> _extent = ValueNotifier<double>(0.7);
  bool _closing = false;

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  double get _averageGrade {
    double sum = 0;
    int count = 0;
    for (final g in widget.grades) {
      final v = double.tryParse(g.grade.replaceFirst(',', '.'));
      if (v != null && v >= 1 && v <= 5) {
        sum += v;
        count++;
      }
    }
    return count > 0 ? (sum / count) : 0;
  }

  String get _averageStr {
    final a = _averageGrade;
    if (a == 0) return '—';
    return a.toStringAsFixed(a.truncateToDouble() == a ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<GradeListItem>.from(widget.grades)
      ..sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));
    final screenHeight = MediaQuery.sizeOf(context).height;

    return ValueListenableBuilder<double>(
      valueListenable: _extent,
      builder: (context, extent, _) {
        final barrierHeight = screenHeight * (1 - extent);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(height: barrierHeight),
            ),
            SizedBox(
              height: screenHeight * extent,
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (n) {
                  if (n.extent != _extent.value) _extent.value = n.extent;
                  if (!_closing && n.extent <= n.minExtent + 0.05) {
                    _closing = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) Navigator.of(context).pop();
                    });
                  }
                  return false;
                },
                child: DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.35,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.35, 0.7, 1.0],
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) {
                    return Material(
          color: AppColors.surfaceLight,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppUi.radiusXl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppUi.screenPaddingH, 20, AppUi.screenPaddingH, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.subjectName,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _gradeBgColor(_averageStr),
                        borderRadius: BorderRadius.circular(AppUi.radiusL),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _averageStr,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: _gradeTextColor(_averageStr),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 20),
              Expanded(
                child: sorted.isEmpty
                    ? Center(
                        child: Text(
                          'Нет оценок',
                          style: AppTextStyle.inter(
                            fontSize: 14,
                            color: AppColors.caption,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(AppUi.screenPaddingH, 0, AppUi.screenPaddingH, 24),
                        itemCount: sorted.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppUi.spacingS),
                        itemBuilder: (context, index) {
                          final item = sorted[index];
                          return _GradeRow(item: item);
                        },
                      ),
              ),
            ],
          ),
        );
      },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _gradeTextColor(String grade) {
    final (c, _) = GradeItemTile.colorsForGrade(grade);
    return c;
  }

  Color _gradeBgColor(String grade) {
    final (_, bg) = GradeItemTile.colorsForGrade(grade);
    return bg;
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.item});

  final GradeListItem item;

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  @override
  Widget build(BuildContext context) {
    final dateStr = item.date != null
        ? '${item.date!.day} ${_months[item.date!.month - 1]}'
        : '';
    final typeStr = item.type ?? item.subtitle;
    final (gradeTextColor, gradeBgColor) = GradeItemTile.colorsForGrade(item.grade);
    final subtitleColor = item.isSpecialType ? gradeTextColor : AppColors.caption;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppUi.radiusS),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: AppUi.contentPaddingH, vertical: AppUi.contentPaddingV),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppUi.radiusS),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (typeStr.isNotEmpty) ...[
                  if (dateStr.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    typeStr,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: gradeBgColor,
              borderRadius: BorderRadius.circular(AppUi.radiusS),
            ),
            alignment: Alignment.center,
            child: Text(
              item.grade,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: gradeTextColor,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
