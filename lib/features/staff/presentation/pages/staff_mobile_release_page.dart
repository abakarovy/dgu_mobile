import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../widgets/staff_admin_ui.dart';
import 'staff_admin_sections.dart';

/// Настройки мобильного приложения: `GET/PUT /api/mobile-app-release/admin`.
class StaffMobileReleasePage extends StatefulWidget {
  const StaffMobileReleasePage({super.key});

  @override
  State<StaffMobileReleasePage> createState() => _StaffMobileReleasePageState();
}

class _StaffMobileReleasePageState extends State<StaffMobileReleasePage> {
  static const _tabs = ['Версии', 'Диалог', 'Ссылки на сторы'];

  int _tab = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;
  String? _lastSavedAt;

  bool _checkOnLaunch = true;
  bool _forceUpdate = false;

  final _latestCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _rustoreCtrl = TextEditingController();
  final _iosCtrl = TextEditingController();
  final _androidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _latestCtrl.dispose();
    _minCtrl.dispose();
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _rustoreCtrl.dispose();
    _iosCtrl.dispose();
    _androidCtrl.dispose();
    super.dispose();
  }

  void _applyData(Map<String, dynamic> data) {
    _checkOnLaunch = _bool(data['check_updates_on_launch'] ?? data['check_on_launch'], true);
    _forceUpdate = _bool(data['force_update'] ?? data['forceUpdate'], false);
    _latestCtrl.text = _str(data['latest_version'] ?? data['latestVersion']);
    _minCtrl.text = _str(data['min_version'] ?? data['minVersion']);
    _titleCtrl.text = _str(data['update_title'] ?? data['title']);
    _messageCtrl.text = _str(data['update_message'] ?? data['message']);
    _rustoreCtrl.text = _str(data['store_url_rustore'] ?? data['storeUrlRustore']);
    _iosCtrl.text = _str(data['store_url_ios'] ?? data['storeUrlIos']);
    _androidCtrl.text = _str(data['store_url_android'] ?? data['storeUrlAndroid']);
    _lastSavedAt = _str(
      data['updated_at'] ?? data['last_saved_at'] ?? data['lastSavedAt'],
      fallback: null,
    );
  }

  bool _bool(Object? v, bool fallback) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return fallback;
  }

  String _str(Object? v, {String? fallback = ''}) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return fallback ?? '';
    return s;
  }

  Map<String, dynamic> _buildBody() => {
    'check_updates_on_launch': _checkOnLaunch,
    'latest_version': _latestCtrl.text.trim(),
    'min_version': _minCtrl.text.trim(),
    'force_update': _forceUpdate,
    'update_title': _titleCtrl.text.trim(),
    'update_message': _messageCtrl.text.trim(),
    'store_url_rustore': _rustoreCtrl.text.trim(),
    'store_url_ios': _iosCtrl.text.trim(),
    'store_url_android': _androidCtrl.text.trim(),
  };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AppContainer.staffModulesApi.getMobileReleaseAdmin();
      if (!mounted) return;
      setState(() {
        _applyData(data);
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

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      final data = await AppContainer.staffModulesApi.updateMobileReleaseAdmin(
        _buildBody(),
      );
      if (!mounted) return;
      setState(() {
        _applyData(data);
        _saving = false;
        _success = 'Сохранено';
      });
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

  String _formatSavedAt(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final sec = local.second.toString().padLeft(2, '0');
    return '$d.$m.${local.year}, $h:$min:$sec';
  }

  Widget _versionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _latestCtrl,
          decoration: StaffAdminUi.fieldDecoration('Актуальная версия в сторе'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _minCtrl,
          decoration: StaffAdminUi.fieldDecoration('Минимальная версия'),
        ),
        const SizedBox(height: 12),
        StaffAdminUi.adminCheckboxTile(
          label:
              'Принудительное обновление — для всех, у кого версия ниже актуальной '
              '(блокирующий диалог на splash)',
          value: _forceUpdate,
          onChanged: (v) => setState(() => _forceUpdate = v ?? false),
        ),
      ],
    );
  }

  Widget _dialogTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleCtrl,
          decoration: StaffAdminUi.fieldDecoration('Заголовок'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageCtrl,
          minLines: 4,
          maxLines: 8,
          decoration: StaffAdminUi.fieldDecoration(
            'Текст сообщения',
            hint: 'Что нового в этой версии…',
          ),
        ),
      ],
    );
  }

  Widget _storesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _rustoreCtrl,
          decoration: StaffAdminUi.fieldDecoration('RuStore (Android, приоритет)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _iosCtrl,
          decoration: StaffAdminUi.fieldDecoration('App Store (iOS)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _androidCtrl,
          decoration: StaffAdminUi.fieldDecoration('Запасная ссылка Android'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffAdminSectionScaffold(
      title: 'Мобильное приложение',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: StaffAdminUi.tabPaddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StaffAdminUi.adminCheckboxTile(
                    label: 'Проверять обновления при запуске приложения',
                    value: _checkOnLaunch,
                    onChanged: (v) => setState(() => _checkOnLaunch = v ?? false),
                  ),
                  const SizedBox(height: 16),
                  StaffAdminUi.segmentSwitch(
                    labels: _tabs,
                    selectedIndex: _tab,
                    activeColor: StaffAdminUi.navy,
                    onSelected: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 16),
                  StaffAdminUi.sectionCard(
                    title: _tabs[_tab],
                    child: switch (_tab) {
                      0 => _versionsTab(),
                      1 => _dialogTab(),
                      _ => _storesTab(),
                    },
                  ),
                  if (_lastSavedAt != null && _lastSavedAt!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Последнее сохранение: ${_formatSavedAt(_lastSavedAt)}',
                      style: AppTextStyle.inter(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: AppTextStyle.inter(color: AppColors.grade2Text)),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _success!,
                      style: AppTextStyle.inter(color: const Color(0xFF15803D)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  StaffAdminUi.darkButton(
                    label: _saving ? 'Сохранение…' : 'Сохранить',
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }
}
