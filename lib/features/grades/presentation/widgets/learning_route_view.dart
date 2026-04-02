import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Маршрут: список дисциплин/сессии в стиле вкладки «Сессия».
class LearningRouteView extends StatelessWidget {
  const LearningRouteView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Сессия 1 • Дисциплины',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 13.57,
              height: 1.0,
              color: const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 24),
          ..._session1Items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _DisciplineSessionCard(item: e),
            ),
          ),
        ],
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
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _RoutePill(
                text: 'Форма • ${item.controlForm}',
                variant: _RoutePillVariant.form,
              ),
              _RoutePill(
                text: 'Дата • ${item.examDate}',
                variant: _RoutePillVariant.date,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _RoutePillVariant { form, date }

class _RoutePill extends StatelessWidget {
  const _RoutePill({
    required this.text,
    required this.variant,
  });

  final String text;
  final _RoutePillVariant variant;

  (Color bg, Color border, Color text) _palette() {
    switch (variant) {
      case _RoutePillVariant.form:
        return (const Color(0x242563EB), const Color(0xFF2563EB), const Color(0xFF2563EB));
      case _RoutePillVariant.date:
        return (const Color(0x1464748B), const Color(0xFF64748B), const Color(0xFF64748B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, br, tc) = _palette();
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.65),
        border: Border.all(color: br, width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 8.65,
            height: 1.0,
            color: tc,
          ),
        ),
      ),
    );
  }
}

class _RouteDiscipline {
  const _RouteDiscipline({
    required this.title,
    required this.controlForm,
    required this.examDate,
  });

  final String title;
  final String controlForm;
  /// Дата экзамена/зачёта или период практики «09.02.2026 - 21.02.2026»
  final String examDate;
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
