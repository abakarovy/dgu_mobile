import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../core/widgets/app_date_range_picker.dart';
import '../widgets/staff_admin_dialog.dart';
import '../widgets/staff_admin_ui.dart';
import '../widgets/staff_student_search_picker.dart';

/// Обёртка для экранов админ-разделов.
class StaffAdminSectionScaffold extends StatelessWidget {
  const StaffAdminSectionScaffold({
    super.key,
    required this.title,
    this.banner,
    this.actions,
    required this.body,
    this.floatingAction,
  });

  final String title;
  final String? banner;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffAdminUi.bg,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text(title, style: appHeaderNestedTitleStyle),
        showNotificationIcon: false,
        actions: actions ?? const [],
      ),
      floatingActionButton: floatingAction,
      body: body,
    );
  }
}

/// Модерация портфолио.
class StaffModerationAdminPage extends StatefulWidget {
  const StaffModerationAdminPage({super.key});

  @override
  State<StaffModerationAdminPage> createState() => _StaffModerationAdminPageState();
}

class _StaffModerationAdminPageState extends State<StaffModerationAdminPage> {
  List<Map<String, dynamic>> _items = [];
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
      final items = await AppContainer.staffModulesApi.getModerationPending();
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
        _error = 'Не удалось загрузить очередь';
      });
    }
  }

  Future<void> _decide(Map<String, dynamic> item, String status) async {
    final id = item['id'];
    if (id == null) return;
    try {
      await AppContainer.staffModulesApi.patchModeration(
        id is int ? id : int.parse('$id'),
        {'status': status},
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffAdminSectionScaffold(
      title: 'Модерация',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: StaffAdminUi.tabPaddingAll,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null)
                    Text(_error!, style: AppTextStyle.inter(color: AppColors.grade2Text))
                  else if (_items.isEmpty)
                    StaffAdminUi.sectionCard(
                      title: 'На проверке',
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.lightGrey,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Нет записей на модерации',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.inter(color: AppColors.grey),
                        ),
                      ),
                    )
                  else
                    StaffAdminUi.sectionCard(
                      title: 'На проверке',
                      child: StaffStripedTable(
                        columns: const ['Студент', 'Документ', 'Действия'],
                        rows: [
                          for (final item in _items)
                            [
                              Text(
                                '${item['student_name'] ?? item['full_name'] ?? '—'}',
                                style: AppTextStyle.inter(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                '${item['title'] ?? item['document_type'] ?? '—'}',
                                style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey),
                              ),
                              Wrap(
                                spacing: 6,
                                children: [
                                  StaffAdminUi.outlineButton(
                                    label: 'Принять',
                                    compact: true,
                                    onPressed: () => _decide(item, 'approved'),
                                  ),
                                  StaffAdminUi.outlineButton(
                                    label: 'Отклонить',
                                    compact: true,
                                    onPressed: () => _decide(item, 'rejected'),
                                  ),
                                ],
                              ),
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

/// Рассылка оценок.
class StaffWeeklyGradesAdminPage extends StatefulWidget {
  const StaffWeeklyGradesAdminPage({super.key});

  @override
  State<StaffWeeklyGradesAdminPage> createState() => _StaffWeeklyGradesAdminPageState();
}

class _StaffWeeklyGradesAdminPageState extends State<StaffWeeklyGradesAdminPage> {
  List<Map<String, dynamic>> _students = [];
  bool _studentsLoading = true;
  int? _selectedStudentId;
  DateTime? _from;
  DateTime? _to;
  bool _forParent = false;
  bool _loading = false;
  String? _preview;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStudents());
  }

  Future<void> _loadStudents() async {
    setState(() => _studentsLoading = true);
    try {
      final users = await AppContainer.staffModulesApi.getUsers();
      if (!mounted) return;
      setState(() {
        _students = users
            .where(
              (u) => (u['role'] ?? '').toString().toLowerCase() == 'student',
            )
            .toList();
        _studentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _studentsLoading = false);
    }
  }

  Map<String, dynamic> _periodPayload() {
    final payload = <String, dynamic>{};
    if (_from != null) {
      payload['period_from'] = _fmtApi(_from!);
    }
    if (_to != null) {
      payload['period_to'] = _fmtApi(_to!);
    }
    return payload;
  }

  Map<String, dynamic> _singleStudentPayload() {
    return {
      ..._periodPayload(),
      'student_user_id': _selectedStudentId,
    };
  }

  String _formatPreview(Map<String, dynamic> data) {
    final buf = StringBuffer();
    final weekLabel = data['week_label']?.toString();
    if (weekLabel != null && weekLabel.isNotEmpty) {
      buf.writeln(weekLabel);
    }
    final student = data['student_name']?.toString();
    if (student != null && student.isNotEmpty) {
      buf.writeln('Студент: $student');
    }
    final rows = data['rows'];
    if (rows is List) {
      if (rows.isEmpty) {
        buf.writeln('Нет оценок за период.');
      } else {
        for (final raw in rows) {
          if (raw is! Map) continue;
          final row = Map<String, dynamic>.from(raw);
          buf.writeln(
            '${row['date'] ?? '—'} · ${row['subject_name'] ?? '—'} — '
            '${row['grade_value'] ?? '—'} (${row['grade_type'] ?? '—'})',
          );
        }
      }
    }
    final text = buf.toString().trim();
    return text.isEmpty ? data.toString() : text;
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      title: isFrom ? 'Дата «с»' : 'Дата «по»',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _previewGrades() async {
    if (!_canSingleActions) return;
    setState(() {
      _loading = true;
      _message = null;
      _preview = null;
    });
    try {
      final data = await AppContainer.staffModulesApi.previewWeeklyGrades(
        _singleStudentPayload(),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _preview = _formatPreview(data);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = '$e';
      });
    }
  }

  Future<void> _send() async {
    if (!_canSingleActions) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await AppContainer.staffModulesApi.sendWeeklyGrades(
        _singleStudentPayload(),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = result['message']?.toString() ?? 'Рассылка отправлена';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = '$e';
      });
    }
  }

  Future<void> _sendBulk() async {
    if (!_hasPeriod) return;
    final ok = await showStaffCenteredDialog<bool>(
      context,
      child: StaffAdminDialogFrame(
        title: 'Массовая рассылка',
        onClose: () => Navigator.of(context).pop(false),
        body: Text(
          'Отправить оценки всем студентам за выбранный период '
          '${_fmtDisplay(_from!)} — ${_fmtDisplay(_to!)}?',
          style: AppTextStyle.inter(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textPrimary,
          ),
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StaffAdminUi.primaryButton(
              label: 'Отправить',
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
            StaffAdminUi.outlineButton(
              label: 'Отмена',
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await AppContainer.staffModulesApi.sendWeeklyGradesBulk(
        _periodPayload(),
      );
      if (!mounted) return;
      final sent = result['emails_sent'];
      final failed = result['emails_failed'];
      setState(() {
        _loading = false;
        _message = sent != null
            ? 'Массовая рассылка: отправлено $sent, ошибок ${failed ?? 0}'
            : 'Массовая рассылка запущена';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = '$e';
      });
    }
  }

  String _fmtDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _fmtApi(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _hasPeriod => _from != null && _to != null;

  bool get _canSingleActions => _hasPeriod && _selectedStudentId != null;

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: StaffAdminUi.fieldDecoration(
          label,
          hint: 'дд.мм.гггг',
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppColors.grey.withValues(alpha: 0.85),
          ),
        ),
        child: Text(
          value == null ? 'дд.мм.гггг' : _fmtDisplay(value),
          style: AppTextStyle.inter(
            fontSize: 14,
            color: value == null ? AppColors.grey : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffAdminSectionScaffold(
      title: 'Рассылка оценок',
      body: ListView(
        padding: StaffAdminUi.tabPaddingAll,
        children: [
          StaffAdminUi.sectionCard(
            title: 'Параметры',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Кого выбираем',
                  style: AppTextStyle.inter(
                    fontSize: 13,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                RadioGroup<bool>(
                  groupValue: _forParent,
                  onChanged: (v) {
                    if (v != null) setState(() => _forParent = v);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Студент'),
                          value: false,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Родитель'),
                          value: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_studentsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  StaffStudentSearchPicker(
                    students: _students,
                    enabled: _students.isNotEmpty,
                    includeBookNumber: true,
                    hint: 'Поиск по ФИО, email или зачётке',
                    onSelected: (id) => setState(() => _selectedStudentId = id),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Период оценок',
                  style: AppTextStyle.inter(
                    fontSize: 13,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: 'С',
                        value: _from,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField(
                        label: 'По',
                        value: _to,
                        onTap: () => _pickDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StaffAdminUi.darkButton(
                  label: 'Превью из 1С',
                  fullWidth: true,
                  onPressed: _loading || !_canSingleActions ? null : _previewGrades,
                ),
                const SizedBox(height: 8),
                StaffAdminUi.primaryButton(
                  label: 'Отправить одному',
                  fullWidth: true,
                  onPressed: _loading || !_canSingleActions ? null : _send,
                ),
                const SizedBox(height: 8),
                StaffAdminUi.outlineNavyButton(
                  label: 'Массовая рассылка',
                  fullWidth: true,
                  onPressed: _loading || !_hasPeriod ? null : _sendBulk,
                ),
                if (_preview != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _preview!,
                    style: AppTextStyle.inter(fontSize: 13, height: 1.4),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: AppTextStyle.inter(
                      color: _message!.contains('отправлен')
                          ? const Color(0xFF15803D)
                          : AppColors.grade2Text,
                    ),
                  ),
                ],
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Настройки системы.
class StaffSettingsAdminPage extends StatefulWidget {
  const StaffSettingsAdminPage({super.key});

  @override
  State<StaffSettingsAdminPage> createState() => _StaffSettingsAdminPageState();
}

class _StaffSettingsAdminPageState extends State<StaffSettingsAdminPage> {
  Map<String, dynamic> _settings = {};
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
      final data = await AppContainer.staffModulesApi.getAdminSettings();
      if (!mounted) return;
      setState(() {
        _settings = data;
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
        _error = 'Не удалось загрузить настройки';
      });
    }
  }

  bool _bool(String key, {bool fallback = false}) {
    final v = _settings[key];
    if (v is bool) return v;
    if (v == 'true' || v == 1) return true;
    if (v == 'false' || v == 0) return false;
    return fallback;
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() => _settings[key] = value);
    try {
      final updated = await AppContainer.staffModulesApi.patchAdminSettings({key: value});
      if (!mounted) return;
      setState(() => _settings = {..._settings, ...updated});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffAdminSectionScaffold(
      title: 'Настройки',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppUi.screenPaddingH),
                children: [
                  StaffAdminUi.pageTitle('Настройки системы'),
                  const SizedBox(height: 10),
                  StaffAdminUi.infoBanner(
                    'Глобальные параметры, уведомления и системные опции.',
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: AppTextStyle.inter(color: AppColors.grade2Text))
                  else
                    StaffAdminUi.sectionCard(
                      title: 'Системные опции',
                      child: Column(
                        children: [
                          _toggleRow(
                            'Email-уведомления',
                            'email_notifications',
                            'Рассылка писем пользователям',
                          ),
                          _toggleRow(
                            'Публичность кейсов',
                            'upk_cases_public',
                            'Показывать кейсы УПК на сайте',
                          ),
                          _toggleRow(
                            'Регистрация студентов',
                            'student_registration_enabled',
                            'Самостоятельная регистрация на сайте',
                          ),
                          _toggleRow(
                            'Режим обслуживания',
                            'maintenance_mode',
                            'Сайт недоступен для посетителей',
                          ),
                          _toggleRow(
                            'Автопубликация новостей',
                            'auto_publish_news',
                            'Публиковать новости сразу после создания',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _toggleRow(String title, String key, String subtitle) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyle.inter(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey)),
      value: _bool(key),
      activeTrackColor: StaffAdminUi.primaryBlue,
      onChanged: (v) => _toggle(key, v),
    );
  }
}

/// Сведения об ОО.
class StaffEduDisclosureAdminPage extends StatefulWidget {
  const StaffEduDisclosureAdminPage({super.key});

  @override
  State<StaffEduDisclosureAdminPage> createState() => _StaffEduDisclosureAdminPageState();
}

class _StaffEduDisclosureAdminPageState extends State<StaffEduDisclosureAdminPage> {
  List<Map<String, dynamic>> _sections = [];
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
      final items = await AppContainer.staffModulesApi.getEduDisclosureAdminSections();
      if (!mounted) return;
      setState(() {
        _sections = items;
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
        _error = 'Не удалось загрузить разделы';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffAdminSectionScaffold(
      title: 'Сведения об ОО',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppUi.screenPaddingH),
                children: [
                  StaffAdminUi.pageTitle('Сведения об ОО'),
                  const SizedBox(height: 10),
                  StaffAdminUi.infoBanner(
                    'Публичный раздел сайта: тексты, публикации и структура колледжа.',
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: AppTextStyle.inter(color: AppColors.grade2Text))
                  else if (_sections.isEmpty)
                    StaffAdminUi.sectionCard(
                      title: 'Тексты разделов',
                      child: Text(
                        'Разделы не найдены',
                        style: AppTextStyle.inter(color: AppColors.grey),
                      ),
                    )
                  else
                    StaffAdminUi.sectionCard(
                      title: 'Тексты разделов',
                      child: StaffStripedTable(
                        columns: const ['Раздел', 'Действие'],
                        rows: [
                          for (final s in _sections)
                            [
                              Text(
                                '${s['title'] ?? s['name'] ?? s['slug'] ?? '—'}',
                                style: AppTextStyle.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              StaffAdminUi.outlineButton(
                                label: 'Редактировать',
                                compact: true,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Редактор HTML доступен на сайте в полной версии',
                                      ),
                                    ),
                                  );
                                },
                              ),
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
