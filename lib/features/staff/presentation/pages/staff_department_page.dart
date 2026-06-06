import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../shared/widgets/app_header.dart';

/// Кабинет отделения: `/api/cabinet/department/...`.
class StaffDepartmentPage extends StatefulWidget {
  const StaffDepartmentPage({super.key});

  @override
  State<StaffDepartmentPage> createState() => _StaffDepartmentPageState();
}

class _StaffDepartmentPageState extends State<StaffDepartmentPage> {
  Map<String, dynamic>? _me;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _announcements = [];
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
        AppContainer.staffModulesApi.getDepartmentMe(),
        AppContainer.staffModulesApi.getDepartmentGroupsOverview(),
        AppContainer.staffModulesApi.getDepartmentAnnouncements(),
      ]);
      if (!mounted) return;
      setState(() {
        _me = results[0] as Map<String, dynamic>;
        _groups = results[1] as List<Map<String, dynamic>>;
        _announcements = results[2] as List<Map<String, dynamic>>;
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
        _error = 'Не удалось загрузить кабинет';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptName = (_me?['department_name'] ?? _me?['department'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Кабинет отделения', style: appHeaderNestedTitleStyle),
        showNotificationIcon: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppUi.screenPaddingH),
                    children: [
                      if (deptName.isNotEmpty)
                        Text(
                          deptName,
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      const SizedBox(height: AppUi.spacingL),
                      Text('Группы', style: AppTextStyle.inter(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (_groups.isEmpty)
                        Text('Нет данных', style: AppTextStyle.inter(color: AppColors.grey))
                      else
                        ..._groups.map((g) {
                          final title = (g['group_code'] ?? g['name'] ?? g['title'] ?? '').toString();
                          final count = g['students_count'] ?? g['count'];
                          return ListTile(
                            tileColor: Colors.white,
                            title: Text(title),
                            subtitle: count != null ? Text('Студентов: $count') : null,
                          );
                        }),
                      const SizedBox(height: AppUi.spacingL),
                      Text('Объявления', style: AppTextStyle.inter(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (_announcements.isEmpty)
                        Text('Нет объявлений', style: AppTextStyle.inter(color: AppColors.grey))
                      else
                        ..._announcements.map((a) {
                          return ListTile(
                            tileColor: Colors.white,
                            title: Text('${a['title'] ?? 'Объявление'}'),
                            subtitle: Text('${a['body'] ?? ''}', maxLines: 3, overflow: TextOverflow.ellipsis),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
