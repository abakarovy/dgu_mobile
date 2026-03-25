import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Учебный маршрут: карточки в стиле вкладки «Сессия» — форма контроля, дата/период.
class LearningRouteView extends StatelessWidget {
  const LearningRouteView({super.key});

  static const double _pillGap = 8;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppUi.screenPaddingH,
        8,
        AppUi.screenPaddingH,
        AppUi.spacingXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Учебный маршрут',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '4 курс · 2025–2026',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.3,
              color: AppColors.caption,
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Сессия 1 · дисциплины'),
          const SizedBox(height: 10),
          ..._session1Items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppUi.spacingBetweenCards),
              child: _DisciplineSessionCard(item: e),
            ),
          ),
          const SizedBox(height: 8),
          _sectionLabel('Сессия 2 · практики'),
          const SizedBox(height: 10),
          ..._session2Items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppUi.spacingBetweenCards),
              child: _DisciplineSessionCard(item: e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyle.inter(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        height: 1.25,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Одна дисциплина: как карточка «Сессии» — белый блок, внутри чипы label · значение.
class _DisciplineSessionCard extends StatelessWidget {
  const _DisciplineSessionCard({required this.item});

  final _RouteDiscipline item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.contentPaddingH,
        vertical: AppUi.contentPaddingV,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.radiusS),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 4,
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
              height: 1.25,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (item.isPractice) ...[
            _RoutePill(
              label: 'Форма',
              value: item.controlForm,
              variant: _PillVariant.accent,
            ),
            const SizedBox(height: LearningRouteView._pillGap),
            _RoutePill(
              label: 'Период',
              value: item.examDate,
              variant: _PillVariant.date,
              valueMaxLines: 2,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _RoutePill(
                    label: 'Форма',
                    value: item.controlForm,
                    variant: _PillVariant.accent,
                  ),
                ),
                SizedBox(width: LearningRouteView._pillGap),
                Expanded(
                  child: _RoutePill(
                    label: 'Дата',
                    value: item.examDate,
                    variant: _PillVariant.date,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _PillVariant { accent, date }

class _RoutePill extends StatelessWidget {
  const _RoutePill({
    required this.label,
    required this.value,
    required this.variant,
    this.valueMaxLines = 3,
  });

  final String label;
  final String value;
  final _PillVariant variant;
  /// Для длинного периода — перенос на вторую строку внутри чипа
  final int valueMaxLines;

  (Color labelColor, Color valueColor, Color bg, Color border) _style() {
    switch (variant) {
      case _PillVariant.accent:
        return (
          AppColors.notificationSubtitle,
          AppColors.primaryGreen,
          AppColors.backgroundGreen,
          const Color(0x33059669),
        );
      case _PillVariant.date:
        return (
          AppColors.notificationSubtitle,
          AppColors.textPrimary,
          AppColors.backgroundSecondary,
          AppColors.lightGrey.withValues(alpha: 0.7),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (lc, vc, bg, br) = _style();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: br, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.25,
            color: lc,
          ),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: ' · ',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: AppColors.caption,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.25,
                color: vc,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        softWrap: true,
        maxLines: valueMaxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _RouteDiscipline {
  const _RouteDiscipline({
    required this.title,
    required this.controlForm,
    required this.examDate,
    this.isPractice = false,
  });

  final String title;
  final String controlForm;
  /// Дата экзамена/зачёта или период практики «09.02.2026 - 21.02.2026»
  final String examDate;
  /// Практика — подпись «Период» вместо «Дата»
  final bool isPractice;
}

const List<_RouteDiscipline> _session1Items = [
  _RouteDiscipline(
    title: 'Разработка программных модулей',
    controlForm: 'Экзамен',
    examDate: '18.06.2026',
  ),
  _RouteDiscipline(
    title: 'Поддержка и тестирование программных модулей',
    controlForm: 'Дифф. зачёт',
    examDate: '22.06.2026',
  ),
  _RouteDiscipline(
    title: 'Разработка мобильных приложений',
    controlForm: 'Экзамен',
    examDate: '20.06.2026',
  ),
  _RouteDiscipline(
    title: 'Системное программирование',
    controlForm: 'Дифф. зачёт',
    examDate: '24.06.2026',
  ),
  _RouteDiscipline(
    title: 'Технология разработки программного обеспечения',
    controlForm: 'Экзамен',
    examDate: '19.06.2026',
  ),
  _RouteDiscipline(
    title: 'Инструментальные средства разработки ПО',
    controlForm: 'Дифф. зачёт',
    examDate: '23.06.2026',
  ),
  _RouteDiscipline(
    title: 'Математическое моделирование',
    controlForm: 'Дифф. зачёт',
    examDate: '25.06.2026',
  ),
  _RouteDiscipline(
    title: 'Веб-программирование',
    controlForm: 'Экзамен',
    examDate: '17.06.2026',
  ),
];

const List<_RouteDiscipline> _session2Items = [
  _RouteDiscipline(
    title: 'Производственная практика ПМ.01',
    controlForm: 'Дифф. зачёт',
    examDate: '09.02.2026 - 21.02.2026',
    isPractice: true,
  ),
  _RouteDiscipline(
    title: 'Производственная практика ПМ.02',
    controlForm: 'Дифф. зачёт',
    examDate: '23.02.2026 - 21.03.2026',
    isPractice: true,
  ),
  _RouteDiscipline(
    title: 'Производственная практика ПМ.03 (по профилю)',
    controlForm: 'Дифф. зачёт',
    examDate: '23.03.2026 - 04.04.2026',
    isPractice: true,
  ),
  _RouteDiscipline(
    title: 'Производственная практика ПМ.04 (преддипломная)',
    controlForm: 'Дифф. зачёт',
    examDate: '13.04.2026 - 09.05.2026',
    isPractice: true,
  ),
];
