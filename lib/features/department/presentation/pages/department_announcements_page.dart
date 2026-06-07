import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/api/staff_modules_api.dart';
import '../../../staff/presentation/widgets/staff_admin_ui.dart';
import '../../../teacher/presentation/widgets/teacher_shell_scaffold.dart';

/// Объявления для групп отделения — список и форма публикации.
class DepartmentCabinetAnnouncementsPage extends StatefulWidget {
  const DepartmentCabinetAnnouncementsPage({super.key});

  @override
  State<DepartmentCabinetAnnouncementsPage> createState() =>
      _DepartmentCabinetAnnouncementsPageState();
}

class _DepartmentCabinetAnnouncementsPageState
    extends State<DepartmentCabinetAnnouncementsPage> {
  List<Map<String, dynamic>> _announcements = [];
  List<String> _groupCodes = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String? _selectedGroup;
  DateTime? _visibleFrom;
  DateTime? _visibleUntil;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AppContainer.staffModulesApi.getDepartmentAnnouncements(),
        AppContainer.staffModulesApi.getDepartmentGroupsOverview(),
      ]);
      if (!mounted) return;
      final overview = results[1] as DepartmentGroupsOverviewResult;
      final groups = overview.groups;
      final codes = groups
          .map((g) => (g['group_code'] ?? '').toString())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _announcements = results[0] as List<Map<String, dynamic>>;
        _groupCodes = codes;
        if (_selectedGroup == null && codes.isNotEmpty) {
          _selectedGroup = codes.first;
        }
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
        _error = 'Не удалось загрузить объявления';
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_visibleFrom ?? now)
        : (_visibleUntil ?? _visibleFrom ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _visibleFrom = picked;
      } else {
        _visibleUntil = picked;
      }
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Выберите дату';
    return DateFormat('dd.MM.yyyy').format(d);
  }

  Future<void> _submit() async {
    final group = _selectedGroup?.trim();
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (group == null || group.isEmpty) {
      _showSnack('Выберите учебную группу');
      return;
    }
    if (title.isEmpty || body.isEmpty) {
      _showSnack('Заполните заголовок и текст');
      return;
    }
    if (_visibleFrom == null || _visibleUntil == null) {
      _showSnack('Укажите срок показа студентам');
      return;
    }
    if (_visibleUntil!.isBefore(_visibleFrom!)) {
      _showSnack('Дата окончания не может быть раньше начала');
      return;
    }

    setState(() => _submitting = true);
    try {
      await AppContainer.staffModulesApi.createDepartmentAnnouncement({
        'group_code': group,
        'title': title,
        'body': body,
        'visible_from': DateFormat('yyyy-MM-dd').format(_visibleFrom!),
        'visible_until': DateFormat('yyyy-MM-dd').format(_visibleUntil!),
      });
      if (!mounted) return;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() {
        _visibleFrom = null;
        _visibleUntil = null;
      });
      _showSnack('Объявление опубликовано');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Не удалось опубликовать');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
            Text(
              'Новое объявление',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: AppTextStyle.inter(color: AppColors.grade2Text))
            else ...[
              _formField(
                label: 'Учебная группа',
                child: DropdownButtonFormField<String>(
                  key: ValueKey('group-$_selectedGroup-${_groupCodes.length}'),
                  initialValue: _groupCodes.contains(_selectedGroup)
                      ? _selectedGroup
                      : null,
                  decoration: _inputDecoration(),
                  items: [
                    for (final c in _groupCodes)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _selectedGroup = v),
                ),
              ),
              const SizedBox(height: 10),
              _formField(
                label: 'Заголовок',
                child: TextField(
                  controller: _titleCtrl,
                  decoration: _inputDecoration(hint: 'Краткий заголовок'),
                ),
              ),
              const SizedBox(height: 10),
              _formField(
                label: 'Текст',
                child: TextField(
                  controller: _bodyCtrl,
                  maxLines: 5,
                  decoration: _inputDecoration(hint: 'Текст объявления'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Срок показа студентам',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      label: 'Дата начала',
                      value: _formatDate(_visibleFrom),
                      onTap: () => unawaited(_pickDate(isFrom: true)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateTile(
                      label: 'Дата окончания',
                      value: _formatDate(_visibleUntil),
                      onTap: () => unawaited(_pickDate(isFrom: false)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: StaffAdminUi.pillControlHeight,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: StaffAdminUi.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Опубликовать',
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ранее опубликованные',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              if (_announcements.isEmpty)
                Text(
                  'Объявлений пока нет',
                  style: AppTextStyle.inter(color: AppColors.grey),
                )
              else
                ..._announcements.map(_announcementCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _formField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: StaffAdminUi.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: StaffAdminUi.cardBorder),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StaffAdminUi.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyle.inter(fontSize: 11, color: AppColors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyle.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _announcementCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Объявление').toString();
    final group = (item['group_code'] ?? '').toString();
    final body = (item['body'] ?? '').toString();
    final from = item['visible_from']?.toString();
    final until = item['visible_until']?.toString();
    String period = '';
    if (from != null && until != null) {
      try {
        period =
            '${DateFormat('dd.MM.yyyy').format(DateTime.parse(from))} — ${DateFormat('dd.MM.yyyy').format(DateTime.parse(until))}';
      } catch (_) {
        period = '$from — $until';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: StaffAdminUi.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            if (group.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                group,
                style: AppTextStyle.inter(fontSize: 12, color: StaffAdminUi.primaryBlue),
              ),
            ],
            if (period.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                period,
                style: AppTextStyle.inter(fontSize: 11, color: AppColors.grey),
              ),
            ],
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.inter(fontSize: 13, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
