import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../features/student/presentation/pages/scholarship_rating_page.dart';
import '../../domain/staff_user_name_format.dart';
import '../widgets/staff_admin_ui.dart';
import 'staff_admin_sections.dart';

/// Модерация стипендиального рейтинга (как на сайте).
class StaffScholarshipAdminPage extends StatefulWidget {
  const StaffScholarshipAdminPage({super.key});

  @override
  State<StaffScholarshipAdminPage> createState() =>
      _StaffScholarshipAdminPageState();
}

class _StaffScholarshipAdminPageState extends State<StaffScholarshipAdminPage> {
  static const _tabs = ['На проверке', 'Завершённые'];

  int _tab = 0;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = _tab == 0
          ? await AppContainer.staffModulesApi.getScholarshipRatingAdminPending()
          : await AppContainer.staffModulesApi.getScholarshipRatingAdminCompleted(
              search: _searchCtrl.text,
            );
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
        _error = 'Не удалось загрузить заявки';
      });
    }
  }

  void _setTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
    unawaited(_load());
  }

  int? _entryId(Map<String, dynamic> item) {
    final raw = item['id'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  String _studentLabel(Map<String, dynamic> item) {
    final fromUser = item['student'];
    if (fromUser is Map) {
      final name = StaffUserNameFormat.displayNameFromUser(
        Map<String, dynamic>.from(fromUser),
      );
      if (name.isNotEmpty && name != '—') return name;
    }
    for (final key in ['student_name', 'student_fio', 'full_name', 'fio']) {
      final v = item[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '—';
  }

  String _criterionLabel(Map<String, dynamic> item) {
    for (final key in ['criterion_title', 'criterion_name', 'title', 'criterion']) {
      final v = item[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return 'Заявка';
  }

  Future<void> _approve(Map<String, dynamic> item) async {
    final id = _entryId(item);
    if (id == null) return;
    try {
      await AppContainer.staffModulesApi.patchScholarshipRatingAdmin(id, {
        'status': 'approved',
        'approved_points':
            item['suggested_points'] ?? item['approved_points'],
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _reject(Map<String, dynamic> item) async {
    final id = _entryId(item);
    if (id == null) return;
    try {
      await AppContainer.staffModulesApi.patchScholarshipRatingAdmin(id, {
        'status': 'rejected',
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = _entryId(item);
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text(
          'Итоговые баллы студента будут пересчитаны автоматически.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppContainer.staffModulesApi.deleteScholarshipRatingAdmin(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _entryCard(Map<String, dynamic> item) {
    final status = scholarshipRatingEntryStatusRu(item['status']);
    final points = item['approved_points'] ?? item['suggested_points'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StaffAdminUi.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _studentLabel(item),
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _criterionLabel(item),
            style: AppTextStyle.inter(fontSize: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            'Статус: $status · Баллы: ${points ?? '—'}',
            style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 10),
          if (_tab == 0)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StaffAdminUi.primaryButton(
                  label: 'Одобрить',
                  compact: true,
                  onPressed: () => unawaited(_approve(item)),
                ),
                StaffAdminUi.outlineButton(
                  label: 'Отклонить',
                  compact: true,
                  onPressed: () => unawaited(_reject(item)),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: StaffAdminUi.outlineButton(
                label: 'Удалить',
                compact: true,
                onPressed: () => unawaited(_delete(item)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emptyText = _tab == 0
        ? 'Нет заявок в ожидании.'
        : 'В архиве пока нет записей.';

    return StaffAdminSectionScaffold(
      title: 'Стипендиальный рейтинг',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: StaffAdminUi.tabPaddingAll,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: StaffAdminUi.segmentSwitch(
                    labels: _tabs,
                    selectedIndex: _tab,
                    onSelected: _setTab,
                  ),
                ),
                const SizedBox(width: 8),
                StaffAdminUi.outlineButton(
                  label: 'Обновить очередь',
                  compact: true,
                  onPressed: _loading ? null : _load,
                ),
              ],
            ),
            if (_tab == 1) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                decoration: StaffAdminUi.fieldDecoration(
                  'Поиск по ФИО',
                  hint: 'начните вводить…',
                ),
                onSubmitted: (_) => unawaited(_load()),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: StaffAdminUi.outlineButton(
                  label: 'Найти',
                  compact: true,
                  onPressed: _load,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: AppTextStyle.inter(color: AppColors.grade2Text))
            else
              StaffAdminUi.sectionCard(
                title: _tabs[_tab],
                child: _items.isEmpty
                    ? Text(
                        emptyText,
                        style: AppTextStyle.inter(color: AppColors.grey),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < _items.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _entryCard(_items[i]),
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
