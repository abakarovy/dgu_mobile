import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../staff/presentation/widgets/staff_admin_ui.dart';

/// Материалы для групп: `GET /api/materials/group/{group_id}`.
class TeacherMaterialsPage extends StatefulWidget {
  const TeacherMaterialsPage({super.key});

  @override
  State<TeacherMaterialsPage> createState() => _TeacherMaterialsPageState();
}

class _TeacherMaterialsPageState extends State<TeacherMaterialsPage> {
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _materials = [];
  int? _selectedGroupId;
  bool _loadingGroups = true;
  bool _loadingMaterials = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadGroups());
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loadingGroups = true;
      _error = null;
    });
    try {
      final groups = await AppContainer.staffModulesApi.getGroupsAdmin();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loadingGroups = false;
        if (groups.isNotEmpty && _selectedGroupId == null) {
          _selectedGroupId = _parseId(groups.first['id']);
        }
      });
      if (_selectedGroupId != null) {
        await _loadMaterials();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGroups = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingGroups = false;
        _error = 'Не удалось загрузить группы';
      });
    }
  }

  Future<void> _loadMaterials() async {
    final gid = _selectedGroupId;
    if (gid == null) return;
    setState(() => _loadingMaterials = true);
    try {
      final items = await AppContainer.staffModulesApi.getGroupMaterials(gid);
      if (!mounted) return;
      setState(() {
        _materials = items;
        _loadingMaterials = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMaterials = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMaterials = false;
        _error = 'Не удалось загрузить материалы';
      });
    }
  }

  int? _parseId(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  String _groupLabel(Map<String, dynamic> g) =>
      (g['name'] ?? g['title'] ?? 'Группа').toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffAdminUi.bg,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Материалы', style: appHeaderNestedTitleStyle),
        showNotificationIcon: false,
      ),
      body: _loadingGroups
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadGroups();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: StaffAdminUi.tabPaddingAll,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: AppTextStyle.inter(color: AppColors.grade2Text),
                      ),
                    ),
                  if (_groups.isEmpty)
                    Text(
                      'Нет доступных групп',
                      style: AppTextStyle.inter(color: AppColors.grey),
                    )
                  else ...[
                    StaffAdminUi.sectionCard(
                      title: 'Группа',
                      child: StaffAdminUi.pillDropdown<int?>(
                        value: _selectedGroupId,
                        items: _groups
                            .map((g) => _parseId(g['id']))
                            .whereType<int>()
                            .toList(),
                        label: (id) {
                          final g = _groups.firstWhere(
                            (e) => _parseId(e['id']) == id,
                            orElse: () => const {},
                          );
                          return g.isEmpty ? '—' : _groupLabel(g);
                        },
                        onChanged: (id) {
                          if (id == null) return;
                          setState(() => _selectedGroupId = id);
                          unawaited(_loadMaterials());
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    StaffAdminUi.sectionCard(
                      title: 'Файлы',
                      child: _loadingMaterials
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _materials.isEmpty
                              ? Text(
                                  'Материалов пока нет',
                                  style: AppTextStyle.inter(color: AppColors.grey),
                                )
                              : Column(
                                  children: [
                                    for (var i = 0; i < _materials.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 8),
                                      _materialRow(_materials[i]),
                                    ],
                                  ],
                                ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _materialRow(Map<String, dynamic> item) {
    final title = (item['title'] ?? item['name'] ?? 'Материал').toString();
    final file = (item['original_filename'] ?? item['file_name'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppUi.radiusM),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: AppColors.lightBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (file.isNotEmpty)
                  Text(
                    file,
                    style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
