import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../staff/presentation/widgets/staff_admin_ui.dart';
import '../../../teacher/presentation/widgets/teacher_shell_scaffold.dart';
import '../../domain/department_ui_helpers.dart';

/// Кураторы и учебные группы отделения.
class DepartmentCuratorsPage extends StatefulWidget {
  const DepartmentCuratorsPage({super.key});

  @override
  State<DepartmentCuratorsPage> createState() => _DepartmentCuratorsPageState();
}

class _DepartmentCuratorsPageState extends State<DepartmentCuratorsPage> {
  List<({String curator, List<Map<String, dynamic>> groups})> _curators = [];
  List<({String curator, List<Map<String, dynamic>> groups})> _filtered = [];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final curators = departmentCuratorsFromGroups(overview.groups);
      setState(() {
        _curators = curators;
        _applyFilter(_query);
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
        _error = 'Не удалось загрузить кураторов';
      });
    }
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = _curators;
      return;
    }
    _filtered = [
      for (final c in _curators)
        if (c.curator.toLowerCase().contains(q) ||
            c.groups.any(
              (g) => (g['group_code'] ?? '').toString().toLowerCase().contains(q),
            ))
          c,
    ];
  }

  @override
  Widget build(BuildContext context) {
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
            TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по куратору или коду группы…',
                hintStyle: AppTextStyle.inter(fontSize: 14, color: AppColors.grey),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: StaffAdminUi.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: StaffAdminUi.cardBorder),
                ),
              ),
              onChanged: (v) => setState(() {
                _query = v;
                _applyFilter(v);
              }),
            ),
            const SizedBox(height: 10),
            Text(
              'Список построен из сводки групп 1С — только группы, закреплённые за куратором.',
              style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey, height: 1.35),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: AppTextStyle.inter(color: AppColors.grade2Text))
            else if (_filtered.isEmpty)
              Text(
                _query.isEmpty ? 'Нет данных' : 'Ничего не найдено',
                style: AppTextStyle.inter(color: AppColors.grey),
              )
            else
              ..._filtered.map(_curatorCard),
          ],
        ),
      ),
    );
  }

  Widget _curatorCard(({String curator, List<Map<String, dynamic>> groups}) entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: StaffAdminUi.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.curator,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${entry.groups.length}',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: StaffAdminUi.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in entry.groups) _groupBadge(g),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupBadge(Map<String, dynamic> group) {
    final code = (group['group_code'] ?? '').toString();
    final att = group['attendance_percent'];
    final attText = att is num ? ' ${departmentFormatPercent(att)}' : '';
    final lowAtt = att is num && att < 80;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: lowAtt ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: lowAtt ? const Color(0xFFFECACA) : StaffAdminUi.cardBorder,
        ),
      ),
      child: Text(
        '$code$attText',
        style: AppTextStyle.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: lowAtt ? const Color(0xFF991B1B) : AppColors.textPrimary,
        ),
      ),
    );
  }
}
