import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../domain/staff_user_name_format.dart';
import 'staff_admin_ui.dart';
import 'staff_student_search_picker.dart';

Future<T?> _showStaffCenteredDialog<T>(
  BuildContext context, {
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
        ),
        child: child,
      ),
    ),
  );
}

class _StaffDialogFrame extends StatelessWidget {
  const _StaffDialogFrame({
    required this.title,
    required this.body,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: AppTextStyle.inter(
                            fontSize: 12,
                            color: AppColors.grey,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: body,
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: footer!,
            ),
        ],
      ),
    );
  }
}

String _studentListLabel(Map<String, dynamic> user) {
  final name = StaffUserNameFormat.displayNameFromUser(user);
  return name.isNotEmpty && name != '—' ? name : '—';
}

int? _parseId(dynamic raw) => staffParseUserId(raw);

/// Диалог «Открыть группу» — список студентов, добавление и удаление.
Future<bool?> showStaffGroupDetailDialog(
  BuildContext context, {
  required Map<String, dynamic> groupSummary,
  required Map<int, String> teacherNames,
}) {
  return _showStaffCenteredDialog<bool>(
    context,
    child: _StaffGroupDetailDialog(
      groupSummary: groupSummary,
      teacherNames: teacherNames,
    ),
  );
}

class _StaffGroupDetailDialog extends StatefulWidget {
  const _StaffGroupDetailDialog({
    required this.groupSummary,
    required this.teacherNames,
  });

  final Map<String, dynamic> groupSummary;
  final Map<int, String> teacherNames;

  @override
  State<_StaffGroupDetailDialog> createState() =>
      _StaffGroupDetailDialogState();
}

class _StaffGroupDetailDialogState extends State<_StaffGroupDetailDialog> {
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _allStudents = [];
  bool _loading = true;
  String? _error;
  int? _selectedStudentId;
  bool _adding = false;
  int _studentPickerKey = 0;

  int? get _groupId => _parseId(widget.groupSummary['id']);

  String get _groupName =>
      (widget.groupSummary['name'] ?? widget.groupSummary['title'] ?? 'Группа')
          .toString();

  String get _teacherLabel {
    final fromSummary =
        widget.groupSummary['teacher_name'] ?? widget.groupSummary['teacher'];
    if (fromSummary is String && fromSummary.trim().isNotEmpty) {
      return fromSummary.trim();
    }
    if (fromSummary is Map) {
      final n = StaffUserNameFormat.rawFromUser(
        Map<String, dynamic>.from(fromSummary),
      );
      if (n.isNotEmpty) return n;
    }
    final tid = _parseId(
      _group?['teacher_id'] ?? widget.groupSummary['teacher_id'],
    );
    if (tid != null) return widget.teacherNames[tid] ?? '—';
    return '—';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final id = _groupId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Не указан id группы';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AppContainer.staffModulesApi.getGroup(id),
        AppContainer.staffModulesApi.getGroupStudents(id),
        AppContainer.staffModulesApi.getUsers(),
      ]);
      if (!mounted) return;
      final students = results[1] as List<Map<String, dynamic>>;
      final users = results[2] as List<Map<String, dynamic>>;
      final inGroup = students.map(_parseId).whereType<int>().toSet();
      setState(() {
        _group = results[0] as Map<String, dynamic>;
        _students = students;
        _allStudents = users
            .where((u) {
              final role = (u['role'] ?? '').toString().toLowerCase();
              return role == 'student';
            })
            .where((u) {
              final sid = _parseId(u['id']);
              return sid != null && !inGroup.contains(sid);
            })
            .toList();
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
        _error = 'Не удалось загрузить группу';
      });
    }
  }

  Future<void> _removeStudent(Map<String, dynamic> student) async {
    final groupId = _groupId;
    final studentId = _parseId(student['id']);
    if (groupId == null || studentId == null) return;
    try {
      await AppContainer.staffModulesApi.removeStudentFromGroup(
        groupId,
        studentId,
      );
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addStudent() async {
    final groupId = _groupId;
    final studentId = _selectedStudentId;
    if (groupId == null || studentId == null) return;
    setState(() => _adding = true);
    try {
      await AppContainer.staffModulesApi.addStudentToGroup(groupId, studentId);
      if (!mounted) return;
      setState(() {
        _selectedStudentId = null;
        _studentPickerKey++;
      });
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count =
        _group?['students_count'] ??
        widget.groupSummary['students_count'] ??
        _students.length;

    return _StaffDialogFrame(
      title: _groupName,
      subtitle: 'Преподаватель: $_teacherLabel · студентов: $count',
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
          ? Text(
              _error!,
              style: AppTextStyle.inter(color: AppColors.grade2Text),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'СТУДЕНТЫ В ГРУППЕ',
                  style: AppTextStyle.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                if (_students.isEmpty)
                  Text(
                    'В группе пока нет студентов',
                    style: AppTextStyle.inter(color: AppColors.grey),
                  )
                else
                  for (final s in _students) ...[
                    _studentRow(s),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StaffAdminUi.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Добавить студента',
                        style: AppTextStyle.inter(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StaffStudentSearchPicker(
                        key: ValueKey(
                          'picker-$_studentPickerKey-${_allStudents.length}',
                        ),
                        students: _allStudents,
                        enabled: _allStudents.isNotEmpty,
                        onSelected: (id) =>
                            setState(() => _selectedStudentId = id),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: StaffAdminUi.darkButton(
                          label: _adding ? 'Добавление…' : 'Добавить',
                          onPressed: _adding || _selectedStudentId == null
                              ? null
                              : _addStudent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      footer: Align(
        alignment: Alignment.centerRight,
        child: StaffAdminUi.outlineButton(
          label: 'Закрыть',
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
    );
  }

  Widget _studentRow(Map<String, dynamic> student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StaffAdminUi.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _studentListLabel(student),
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _removeStudentButton(onPressed: () => _removeStudent(student)),
        ],
      ),
    );
  }
}

Widget _removeStudentButton({required VoidCallback onPressed}) {
  return SizedBox(
    width: 32,
    height: 32,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFDC2626),
        side: BorderSide(
          color: const Color(0xFFDC2626).withValues(alpha: 0.35),
        ),
        padding: EdgeInsets.zero,
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const CircleBorder(),
      ),
      child: const Icon(Icons.remove, size: 18),
    ),
  );
}

/// Диалог создания / редактирования группы.
Future<bool?> showStaffGroupEditDialog(
  BuildContext context, {
  Map<String, dynamic>? group,
  required List<Map<String, dynamic>> teachers,
}) {
  return _showStaffCenteredDialog<bool>(
    context,
    child: _StaffGroupEditDialog(group: group, teachers: teachers),
  );
}

class _StaffGroupEditDialog extends StatefulWidget {
  const _StaffGroupEditDialog({required this.teachers, this.group});

  final Map<String, dynamic>? group;
  final List<Map<String, dynamic>> teachers;

  bool get isCreate => group == null;

  @override
  State<_StaffGroupEditDialog> createState() => _StaffGroupEditDialogState();
}

class _StaffGroupEditDialogState extends State<_StaffGroupEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _courseCtrl;
  late final TextEditingController _directionCtrl;
  late final TextEditingController _descriptionCtrl;
  int? _teacherId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameCtrl = TextEditingController(text: (g?['name'] ?? '').toString());
    _courseCtrl = TextEditingController(
      text: g?['course'] == null ? '' : '${g!['course']}',
    );
    _directionCtrl = TextEditingController(
      text: (g?['direction'] ?? '').toString(),
    );
    _descriptionCtrl = TextEditingController(
      text: (g?['description'] ?? '').toString(),
    );
    _teacherId = _parseId(g?['teacher_id']);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _courseCtrl.dispose();
    _directionCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Укажите название группы')));
      return;
    }
    final courseRaw = _courseCtrl.text.trim();
    final course = courseRaw.isEmpty ? null : int.tryParse(courseRaw);
    final body = <String, dynamic>{
      'name': name,
      'description': _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      'direction': _directionCtrl.text.trim().isEmpty
          ? null
          : _directionCtrl.text.trim(),
      'course': course,
      if (_teacherId != null) 'teacher_id': _teacherId,
    };

    setState(() => _saving = true);
    try {
      if (widget.isCreate) {
        await AppContainer.staffModulesApi.createGroup(body);
      } else {
        final id = _parseId(widget.group!['id']);
        if (id == null) throw ApiException('Не указан id группы');
        await AppContainer.staffModulesApi.updateGroup(id, body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StaffDialogFrame(
      title: widget.isCreate ? 'Создание группы' : 'Редактирование группы',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: StaffAdminUi.fieldDecoration('Название'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey('teacher-$_teacherId-${widget.teachers.length}'),
            initialValue: _teacherId,
            isExpanded: true,
            decoration: StaffAdminUi.fieldDecoration('Преподаватель'),
            items: [
              for (final t in widget.teachers)
                DropdownMenuItem(
                  value: _parseId(t['id']),
                  child: Text(
                    staffStudentPickerLabel(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _teacherId = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _courseCtrl,
                  keyboardType: TextInputType.number,
                  decoration: StaffAdminUi.fieldDecoration('Курс'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _directionCtrl,
                  decoration: StaffAdminUi.fieldDecoration('Направление'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: StaffAdminUi.fieldDecoration('Описание'),
          ),
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          StaffAdminUi.outlineButton(
            label: 'Отмена',
            onPressed: _saving ? null : () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          StaffAdminUi.primaryButton(
            label: _saving ? 'Сохранение…' : 'Сохранить',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
