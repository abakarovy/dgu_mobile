import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/api/staff_modules_api.dart';
import '../../../staff/presentation/widgets/staff_admin_ui.dart';
import '../../../staff/presentation/widgets/staff_dashboard_widgets.dart';
import '../../../teacher/presentation/widgets/teacher_shell_scaffold.dart';
import '../../domain/department_ui_helpers.dart';

/// Главная кабинета отделения — KPI, критические точки, сводка по группам.
class DepartmentHomePage extends StatefulWidget {
  const DepartmentHomePage({super.key});

  @override
  State<DepartmentHomePage> createState() => _DepartmentHomePageState();
}

class _DepartmentHomePageState extends State<DepartmentHomePage> {
  DepartmentGroupsOverviewResult? _overview;
  bool _loading = true;
  String? _error;

  static const _kpiGap = 10.0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview =
          await AppContainer.staffModulesApi.getDepartmentGroupsOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить данные';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _overview?.groups ?? const [];
    final summary = _overview?.summary;
    final critical = groups.where(departmentGroupIsCritical).toList();

    return TeacherShellScaffold(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            StaffAdminUi.tabPaddingH,
            AppUi.spacingL,
            StaffAdminUi.tabPaddingH,
            32,
          ),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: AppTextStyle.inter(color: AppColors.grade2Text))
            else ...[
              _kpiGrid(summary),
              if (critical.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Критические точки',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                ...critical.map(_criticalCard),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Оперативная сводка по группам',
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    'Групп: ${groups.length}',
                    style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (groups.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: StaffAdminUi.cardDecoration(),
                  child: Text(
                    'Нет данных по группам',
                    style: AppTextStyle.inter(color: AppColors.grey),
                  ),
                )
              else
                ...groups.map(_groupRow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kpiGrid(Map<String, dynamic>? summary) {
    num? n(String key) {
      final v = summary?[key];
      return v is num ? v : null;
    }

    final perf = n('overall_academic_performance_percent');
    final att = n('overall_attendance_percent');
    final totalStudents = n('total_students');
    final budget = n('total_budget_students');
    final contract = n('total_commercial_students');
    final absences = n('total_absences');
    final avgAbs = n('average_absences_per_student');

    final cards = [
      StaffDashboardKpiCard(
        title: 'ОБЩАЯ УСПЕВАЕМОСТЬ',
        value: departmentFormatPercent(perf),
        subtitle: 'по уникальным должникам из 1С',
      ),
      StaffDashboardKpiCard(
        title: 'ПОСЕЩАЕМОСТЬ',
        value: departmentFormatPercent(att),
        subtitle: 'план vs факт из 1С',
      ),
      StaffDashboardKpiCard(
        title: 'КОНТИНГЕНТ',
        value: departmentFormatInt(totalStudents),
        subtitle: budget != null && contract != null
            ? '${departmentFormatInt(budget)} бюджет · ${departmentFormatInt(contract)} договор'
            : null,
      ),
      StaffDashboardKpiCard(
        title: 'ПРОПУСКИ ЗАНЯТИЙ',
        value: departmentFormatInt(absences),
        footer: avgAbs != null
            ? 'в среднем ${avgAbs.toStringAsFixed(1)} на студента'
            : null,
      ),
    ];

    return Column(
      children: [
        _kpiRow(cards[0], cards[1]),
        const SizedBox(height: _kpiGap),
        _kpiRow(cards[2], cards[3]),
      ],
    );
  }

  Widget _kpiRow(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: _kpiGap),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _groupRow(Map<String, dynamic> group) {
    final code = (group['group_code'] ?? '').toString();
    final curator = (group['curator_full_name'] ?? '').toString();
    final att = group['attendance_percent'];
    final debts = group['academic_debts_count'];
    final risk = group['risk_level']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: StaffAdminUi.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              code.isEmpty ? '—' : code,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (curator.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                curator,
                style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: departmentRiskColor(risk).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    departmentRiskLabel(risk),
                    style: AppTextStyle.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: departmentRiskColor(risk),
                    ),
                  ),
                ),
                const Spacer(),
                if (att is num)
                  Text(
                    departmentFormatPercent(att),
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                if (debts is num) ...[
                  const SizedBox(width: 12),
                  Text(
                    '$debts долг.',
                    style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _criticalCard(Map<String, dynamic> group) {
    final code = (group['group_code'] ?? '').toString();
    final att = group['attendance_percent'];
    final attText = att is num ? departmentFormatPercent(att) : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$code: посещаемость около $attText — повышенный риск',
                style: AppTextStyle.inter(
                  fontSize: 13,
                  height: 1.35,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
