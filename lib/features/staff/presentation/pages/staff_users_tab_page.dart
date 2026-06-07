import 'dart:async';



import 'package:flutter/material.dart';



import '../../../../core/constants/app_colors.dart';

import '../../../../core/constants/app_ui.dart';

import '../../../../core/di/app_container.dart';

import '../../../../core/theme/app_text_styles.dart';

import '../../../../data/api/api_exception.dart';

import '../../domain/staff_user_name_format.dart';
import '../../domain/staff_user_status.dart';
import '../../domain/staff_user_roles.dart';

import '../widgets/staff_admin_ui.dart';

import '../widgets/staff_user_form_sheet.dart';



/// Вкладка «Пользователи» в нижней навигации.

enum _UserSortColumn { fio, role, status }

class StaffUsersTabPage extends StatefulWidget {

  const StaffUsersTabPage({super.key});



  @override

  State<StaffUsersTabPage> createState() => _StaffUsersTabPageState();

}



class _StaffUsersTabPageState extends State<StaffUsersTabPage> {

  List<Map<String, dynamic>> _items = [];

  bool _loading = true;

  String? _error;

  String _query = '';

  String _roleFilter = '';

  _UserSortColumn? _sortColumn;

  bool _sortAscending = true;



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

      final items = await AppContainer.staffModulesApi.getUsers();

      if (!mounted) return;

      setState(() {

        _items = items;

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

        _error = 'Не удалось загрузить пользователей';

      });

    }

  }



  List<Map<String, dynamic>> get _filtered {

    final q = _query.trim().toLowerCase();

    return _items.where((u) {

      if (_roleFilter.isNotEmpty) {

        final role = (u['role'] ?? '').toString().trim().toLowerCase();

        if (role != _roleFilter) return false;

      }

      if (q.isEmpty) return true;

      final name = '${u['full_name'] ?? u['fio'] ?? ''}'.toLowerCase();

      final email = '${u['email'] ?? ''}'.toLowerCase();

      return name.contains(q) || email.contains(q);

    }).toList();

  }



  List<Map<String, dynamic>> get _sorted {
    final list = List<Map<String, dynamic>>.from(_filtered);
    if (_sortColumn == null) return list;
    list.sort((a, b) {
      final cmp = switch (_sortColumn!) {
        _UserSortColumn.fio => StaffUserNameFormat.rawFromUser(a)
            .toLowerCase()
            .compareTo(StaffUserNameFormat.rawFromUser(b).toLowerCase()),
        _UserSortColumn.role => StaffUserRoles.labelFor('${a['role']}')
            .compareTo(StaffUserRoles.labelFor('${b['role']}')),
        _UserSortColumn.status => StaffUserStatus.sortKey(a)
            .compareTo(StaffUserStatus.sortKey(b)),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }



  void _toggleSort(int columnIndex) {
    final column = switch (columnIndex) {
      0 => _UserSortColumn.fio,
      1 => _UserSortColumn.role,
      _ => _UserSortColumn.status,
    };
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }



  Future<void> _createUser() async {

    final ok = await showStaffUserFormSheet(context);

    if (ok == true) await _load();

  }



  void _openUser(Map<String, dynamic> user) {
    showStaffUserDetailDialog(
      context,
      user: user,
      onChanged: _load,
    );
  }



  @override

  Widget build(BuildContext context) {

    if (_loading && _items.isEmpty) {

      return const Center(child: CircularProgressIndicator());

    }



    if (_error != null && _items.isEmpty) {

      return Center(

        child: Padding(

          padding: StaffAdminUi.tabPaddingAll,

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text(_error!, textAlign: TextAlign.center),

              const SizedBox(height: 16),

              FilledButton(onPressed: _load, child: const Text('Повторить')),

            ],

          ),

        ),

      );

    }



    final items = _sorted;

    final sortColumnIndex = switch (_sortColumn) {
      _UserSortColumn.fio => 0,
      _UserSortColumn.role => 1,
      _UserSortColumn.status => 2,
      null => null,
    };

    final roleOptions = ['', ...StaffUserRoles.allRoles.map((e) => e.$1)];



    return ColoredBox(

      color: StaffAdminUi.bg,

      child: RefreshIndicator(

        onRefresh: _load,

        child: ListView(

          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(

            StaffAdminUi.tabPaddingH,

            AppUi.spacingM,

            StaffAdminUi.tabPaddingH,

            32,

          ),

          children: [

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(

                  child: StaffAdminUi.pillDropdown<String>(

                    value: _roleFilter,

                    items: roleOptions,

                    label: (v) => v.isEmpty ? 'Все роли' : StaffUserRoles.labelFor(v),

                    onChanged: (v) => setState(() => _roleFilter = v ?? ''),

                  ),

                ),

                const SizedBox(width: 10),

                StaffAdminUi.primaryButton(

                  label: 'Создать',

                  icon: Icons.add,

                  compact: true,

                  onPressed: _createUser,

                ),

              ],

            ),

            const SizedBox(height: 12),

            TextField(

              decoration: StaffAdminUi.fieldDecoration('Поиск', hint: 'По имени или e-mail'),

              onChanged: (v) => setState(() => _query = v),

            ),

            const SizedBox(height: 16),

            StaffAdminUi.sectionCard(

              title: 'Список пользователей',

              subtitle: 'Нажмите на строку для просмотра',

              child: items.isEmpty

                  ? Padding(

                      padding: const EdgeInsets.symmetric(vertical: 24),

                      child: Text(

                        _query.isEmpty && _roleFilter.isEmpty

                            ? 'Список пуст'

                            : 'Ничего не найдено',

                        textAlign: TextAlign.center,

                        style: AppTextStyle.inter(color: AppColors.grey),

                      ),

                    )

                  : StaffStripedTable(

                      columns: const ['ФИО', 'Роль', 'Статус'],

                      sortColumnIndex: sortColumnIndex,

                      sortAscending: _sortAscending,

                      onColumnHeaderTap: _toggleSort,

                      onRowTap: (i) => _openUser(items[i]),

                      rows: [

                        for (final u in items)

                          [

                            StaffUserFioColumn(user: u),

                            Text(

                              StaffUserRoles.labelFor('${u['role']}'),

                              style: AppTextStyle.inter(fontSize: 12),

                            ),

                            StaffAdminUi.userStatusBadge(u),

                          ],

                      ],

                    ),

            ),

          ],

        ),

      ),

    );

  }

}


