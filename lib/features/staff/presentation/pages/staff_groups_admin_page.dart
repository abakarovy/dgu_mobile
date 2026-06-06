import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../domain/staff_user_name_format.dart';
import '../widgets/staff_admin_ui.dart';
import '../widgets/staff_group_sheets.dart';

/// Группы — `GET /api/groups`.
class StaffGroupsAdminPage extends StatefulWidget {
  const StaffGroupsAdminPage({super.key});

  @override
  State<StaffGroupsAdminPage> createState() => _StaffGroupsAdminPageState();
}

class _StaffGroupsAdminPageState extends State<StaffGroupsAdminPage> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _teachers = [];
  Map<int, String> _teacherNames = {};
  bool _loading = true;
  String? _error;

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
      final results = await Future.wait([
        AppContainer.staffModulesApi.getGroupsAdmin(),
        AppContainer.staffModulesApi.getUsers(),
      ]);
      if (!mounted) return;
      final groups = results[0];
      final users = results[1];
      final teachers = users.where((u) {
        final role = (u['role'] ?? '').toString().toLowerCase();
        return role == 'teacher' || u['is_teacher'] == true;
      }).toList();
      final names = <int, String>{};
      for (final t in teachers) {
        final id = _parseId(t['id']);
        if (id == null) continue;
        names[id] = StaffUserNameFormat.rawFromUser(t);
      }
      for (final g in groups) {
        final tid = _parseId(g['teacher_id']);
        if (tid != null && !names.containsKey(tid)) {
          final tn = g['teacher_name'] ?? g['teacher'];
          if (tn is String && tn.trim().isNotEmpty) {
            names[tid] = tn.trim();
          }
        }
      }
      setState(() {
        _items = groups;
        _teachers = teachers;
        _teacherNames = names;
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
        _error = 'Не удалось загрузить группы';
      });
    }
  }

  int? _parseId(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  bool _isActive(Map<String, dynamic> g) {
    final s = g['status'] ?? g['is_active'];
    if (s == false || s == 'inactive') return false;
    return true;
  }

  String _groupName(Map<String, dynamic> g) =>
      (g['name'] ?? g['title'] ?? '—').toString();

  String _teacherName(Map<String, dynamic> g) {
    final direct = g['teacher_name'] ?? g['teacher'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();
    if (direct is Map) {
      final n = StaffUserNameFormat.rawFromUser(
        Map<String, dynamic>.from(direct),
      );
      if (n.isNotEmpty) return n;
    }
    final tid = _parseId(g['teacher_id']);
    if (tid != null) return _teacherNames[tid] ?? '—';
    return '—';
  }

  Future<void> _openGroup(Map<String, dynamic> group) async {
    final changed = await showStaffGroupDetailDialog(
      context,
      groupSummary: group,
      teacherNames: _teacherNames,
    );
    if (changed == true && mounted) await _load();
  }

  Future<void> _editGroup([Map<String, dynamic>? group]) async {
    final changed = await showStaffGroupEditDialog(
      context,
      group: group,
      teachers: _teachers,
    );
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffAdminUi.bg,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Группы', style: appHeaderNestedTitleStyle),
        showNotificationIcon: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: StaffAdminUi.tabPaddingAll,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null)
                    Text(
                      _error!,
                      style: AppTextStyle.inter(color: AppColors.grade2Text),
                    )
                  else
                    StaffAdminUi.sectionCard(
                      title: 'Список групп',
                      subtitle: 'Управление учебными группами.',
                      trailing: _createIconButton(),
                      child: _items.isEmpty
                          ? Text(
                              'Групп пока нет',
                              style: AppTextStyle.inter(color: AppColors.grey),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < _items.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  _groupRow(_items[i]),
                                ],
                              ],
                            ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _createIconButton() {
    return SizedBox(
      width: StaffAdminUi.pillControlHeight,
      height: StaffAdminUi.pillControlHeight,
      child: FilledButton(
        onPressed: () => _editGroup(),
        style: FilledButton.styleFrom(
          backgroundColor: StaffAdminUi.primaryBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Icon(Icons.add, size: 22),
      ),
    );
  }

  Widget _groupRow(Map<String, dynamic> group) {
    final studentsCount =
        group['students_count'] ?? group['student_count'] ?? '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StaffAdminUi.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _groupName(group),
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StaffAdminUi.compactStatusBadge(active: _isActive(group)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Преподаватель: ${_teacherName(group)}',
            style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Студентов: $studentsCount',
            style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StaffAdminUi.darkButton(
                  label: 'Открыть',
                  onPressed: () => _openGroup(group),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StaffAdminUi.outlineButton(
                  label: 'Ред.',
                  compact: true,
                  onPressed: () => _editGroup(group),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
