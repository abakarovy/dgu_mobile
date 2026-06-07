import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../domain/staff_user_name_format.dart';
import '../../domain/staff_user_roles.dart';
import 'staff_admin_ui.dart';

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

String _userText(Map<String, dynamic> user, String key, {String fallback = '—'}) {
  final v = user[key];
  if (v == null) return fallback;
  final s = '$v'.trim();
  return s.isEmpty ? fallback : s;
}

Widget _readOnlyField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: StaffAdminUi.cardBorder),
            ),
            child: Text(
              value,
              style: AppTextStyle.inter(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}

String _detailDialogTitle(Map<String, dynamic> user) {
  final role = (user['role'] ?? '').toString().trim().toLowerCase();
  if (role == 'student') return 'Данные студента';
  return 'Данные пользователя';
}

/// Карточка пользователя: данные + «Редактировать» / «Удалить».
Future<void> showStaffUserDetailDialog(
  BuildContext context, {
  required Map<String, dynamic> user,
  required VoidCallback onChanged,
}) {
  return _showStaffCenteredDialog<void>(
    context,
    child: _StaffUserDetailDialog(user: user, onChanged: onChanged),
  );
}

class _StaffUserDetailDialog extends StatelessWidget {
  const _StaffUserDetailDialog({
    required this.user,
    required this.onChanged,
  });

  final Map<String, dynamic> user;
  final VoidCallback onChanged;

  String get _name =>
      _userText(user, 'full_name', fallback: _userText(user, 'fio'));

  Future<void> _edit(BuildContext context) async {
    Navigator.of(context).pop();
    final ok = await showStaffUserFormSheet(context, user: user);
    if (ok == true) onChanged();
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: Text('Пользователь «$_name» будет деактивирован.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final id = user['id'];
      await AppContainer.staffModulesApi.deactivateUser(
        id is int ? id : int.parse('$id'),
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = StaffUserRoles.labelFor(_userText(user, 'role', fallback: 'student'));
    final book = _userText(user, 'student_book_number', fallback: 'не указана');
    final course = _userText(user, 'course', fallback: 'не указан');
    final direction = _userText(
      user,
      'direction',
      fallback: _userText(user, 'specialty', fallback: 'не указано'),
    );

    return _StaffDialogFrame(
      title: _detailDialogTitle(user),
      subtitle: 'Email — адрес входа в личный кабинет. У студента отдельно указывается контакт родителя.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ФИО',
                    style: AppTextStyle.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: StaffAdminUi.cardBorder),
                    ),
                    child: StaffUserFioColumn(user: user),
                  ),
                ],
              ),
            ),
          ),
          _readOnlyField('Email (логин)', _userText(user, 'email')),
          _readOnlyField('Email родителя', _userText(user, 'parent_email', fallback: 'не указан')),
          _readOnlyField('Роль', role),
          _readOnlyField('Зачётная книжка', book),
          _readOnlyField('Курс', course),
          _readOnlyField('Направление', direction),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Статус',
                    style: AppTextStyle.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StaffAdminUi.userStatusBadge(user),
                ],
              ),
            ),
          ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _delete(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.grade2Text,
                side: BorderSide(color: AppColors.grade2Text.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Удалить'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StaffAdminUi.darkButton(
              label: 'Редактировать',
              onPressed: () => _edit(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Форма создания / редактирования пользователя.
Future<bool?> showStaffUserFormSheet(
  BuildContext context, {
  Map<String, dynamic>? user,
}) {
  return _showStaffCenteredDialog<bool>(
    context,
    child: _StaffUserFormSheet(user: user),
  );
}

class _StaffUserFormSheet extends StatefulWidget {
  const _StaffUserFormSheet({this.user});

  final Map<String, dynamic>? user;

  bool get isEdit => user != null;

  @override
  State<_StaffUserFormSheet> createState() => _StaffUserFormSheetState();
}

class _StaffUserFormSheetState extends State<_StaffUserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fioCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _parentEmailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _password2Ctrl;
  late final TextEditingController _bookCtrl;
  late final TextEditingController _courseCtrl;
  late final TextEditingController _directionCtrl;
  late String _role;
  late bool _active;
  late bool _isTestUser;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _fioCtrl = TextEditingController(text: '${u?['full_name'] ?? u?['fio'] ?? ''}');
    _emailCtrl = TextEditingController(text: '${u?['email'] ?? ''}');
    _parentEmailCtrl = TextEditingController(text: '${u?['parent_email'] ?? ''}');
    _passwordCtrl = TextEditingController();
    _password2Ctrl = TextEditingController();
    _bookCtrl = TextEditingController(text: '${u?['student_book_number'] ?? ''}');
    _courseCtrl = TextEditingController(text: '${u?['course'] ?? ''}');
    _directionCtrl = TextEditingController(text: '${u?['direction'] ?? u?['specialty'] ?? ''}');
    _role = (u?['role'] ?? 'student').toString().trim().toLowerCase();
    if (!StaffUserRoles.allRoles.any((e) => e.$1 == _role)) _role = 'student';
    _isTestUser = u?['is_test_user'] == true;
    if (u?['is_active'] is bool) {
      _active = u!['is_active'] as bool;
    } else {
      final s = u?['status'];
      _active = s == null ||
          s == true ||
          s == 'active' ||
          s == 'Активен' ||
          s == 'активен';
    }
  }

  @override
  void dispose() {
    _fioCtrl.dispose();
    _emailCtrl.dispose();
    _parentEmailCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    _bookCtrl.dispose();
    _courseCtrl.dispose();
    _directionCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'full_name': _fioCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role': _role,
      'is_active': _active,
    };
    if (widget.isEdit) body['is_test_user'] = _isTestUser;
    final pe = _parentEmailCtrl.text.trim();
    if (pe.isNotEmpty) body['parent_email'] = pe;
    final book = _bookCtrl.text.trim();
    if (book.isNotEmpty) body['student_book_number'] = book;
    final course = _courseCtrl.text.trim();
    if (course.isNotEmpty) body['course'] = course;
    final dir = _directionCtrl.text.trim();
    if (dir.isNotEmpty) body['direction'] = dir;
    final pwd = _passwordCtrl.text;
    if (pwd.isNotEmpty) body['password'] = pwd;
    return body;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.isEdit && _passwordCtrl.text.length < 8) {
      setState(() => _error = 'Пароль — минимум 8 символов');
      return;
    }
    if (_passwordCtrl.text.isNotEmpty && _passwordCtrl.text != _password2Ctrl.text) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = AppContainer.staffModulesApi;
      if (widget.isEdit) {
        final id = widget.user!['id'];
        await api.updateUser(id is int ? id : int.parse('$id'), _buildBody());
      } else {
        await api.createUser(_buildBody());
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Не удалось сохранить';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StaffDialogFrame(
      title: widget.isEdit ? 'Редактирование' : 'Новый пользователь',
      subtitle: widget.isEdit
          ? 'Email — адрес входа в личный кабинет. У студента отдельно указывается контакт родителя.'
          : null,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _fioCtrl,
              decoration: StaffAdminUi.fieldDecoration('ФИО'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Укажите ФИО' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: StaffAdminUi.fieldDecoration(
                widget.isEdit ? 'Email (логин)' : 'Email',
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Укажите email' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parentEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: StaffAdminUi.fieldDecoration(
                'Email родителя',
                hint: 'необязательно',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_role),
              initialValue: _role,
              decoration: StaffAdminUi.fieldDecoration('Роль'),
              items: StaffUserRoles.allRoles
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.$1,
                      child: Text(e.$2),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _role = v);
              },
            ),
            if (widget.isEdit) ...[
              const SizedBox(height: 12),
              Text(
                'Статус',
                style: AppTextStyle.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 6),
              StaffAdminUi.adminCheckboxTile(
                label: 'Активен',
                value: _active,
                onChanged: (v) => setState(() => _active = v ?? false),
              ),
              const SizedBox(height: 6),
              StaffAdminUi.adminCheckboxTile(
                label: 'Тестовый пользователь',
                value: _isTestUser,
                onChanged: (v) => setState(() => _isTestUser = v ?? false),
              ),
            ],
            if (!widget.isEdit) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: StaffAdminUi.fieldDecoration(
                  'Пароль',
                  hint: 'минимум 8 символов',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bookCtrl,
                decoration: StaffAdminUi.fieldDecoration(
                  'Зачётная книжка (5 цифр)',
                  hint: 'необязательно',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courseCtrl,
                decoration: StaffAdminUi.fieldDecoration(
                  'Курс',
                  hint: 'необязательно',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _directionCtrl,
                decoration: StaffAdminUi.fieldDecoration(
                  'Направление',
                  hint: 'необязательно',
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: StaffAdminUi.fieldDecoration(
                  'Новый пароль',
                  hint: 'необязательно',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password2Ctrl,
                obscureText: true,
                decoration: StaffAdminUi.fieldDecoration('Повторите пароль'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyle.inter(color: AppColors.grade2Text, fontSize: 13),
              ),
            ],
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          StaffAdminUi.outlineButton(
            label: 'Отмена',
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          StaffAdminUi.darkButton(
            label: widget.isEdit ? 'Сохранить' : 'Создать',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// @deprecated Используйте [showStaffUserDetailDialog].
Future<void> showStaffUserActionsSheet(
  BuildContext context, {
  required Map<String, dynamic> user,
  required VoidCallback onChanged,
}) =>
    showStaffUserDetailDialog(context, user: user, onChanged: onChanged);
