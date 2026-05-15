import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/one_c_my_profile.dart';
import '../../../../data/models/student_ticket_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/dismiss_keyboard_on_tap.dart';

/// Заявка на настройку пароля Wi‑Fi колледжа (POST `/students/me/wifi-password-request`).
/// Логин и курс/группа — как в студенческом билете (только просмотр); пароль ≥ 8 символов.
/// [course_group_hint] не передаём — соберёт бэкенд из профиля по JWT.
class WifiPasswordRequestPage extends StatefulWidget {
  const WifiPasswordRequestPage({super.key});

  @override
  State<WifiPasswordRequestPage> createState() =>
      _WifiPasswordRequestPageState();
}

class _WifiPasswordRequestPageState extends State<WifiPasswordRequestPage> {
  static const Color _labelBlue = Color(0xFF0069FF);

  final _passwordCtrl = TextEditingController();

  UserModel? _me;
  StudentTicketModel? _ticket;
  OneCMyProfile? _oneC;
  GroupModel? _group;

  bool _obscure = true;
  bool _submitting = false;
  bool _loadingProfile = true;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
    unawaited(_refreshProfileFromApi());
  }

  void _hydrateFromCache() {
    try {
      final c = AppContainer.jsonCache.getJsonMap('auth:me');
      if (c != null) _me = UserModel.fromJson(Map<String, dynamic>.from(c));
    } catch (_) {}
    try {
      final t = AppContainer.jsonCache.getJsonMap('mobile:student-ticket');
      if (t != null) {
        _ticket = StudentTicketModel.fromJson(Map<String, dynamic>.from(t));
      }
    } catch (_) {}
    try {
      final p = AppContainer.jsonCache.getJsonMap('1c:my-profile');
      if (p != null) _oneC = OneCMyProfile.fromJson(Map<String, dynamic>.from(p));
    } catch (_) {}
    try {
      final g = AppContainer.jsonCache.getJsonMap('groups:my');
      if (g != null) _group = GroupModel.fromJson(Map<String, dynamic>.from(g));
    } catch (_) {}
  }

  Future<void> _refreshProfileFromApi() async {
    if (!_isStudent) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }
    if (mounted) setState(() => _loadingProfile = true);
    try {
      final me = await AppContainer.authApi
          .getMe()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('auth:me', me.toJson());
      if (mounted) setState(() => _me = me);
    } catch (_) {}

    try {
      final t = await AppContainer.studentTicketApi
          .getMyTicket()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('mobile:student-ticket', t.toJsonMap());
      if (mounted) setState(() => _ticket = t);
    } catch (_) {}

    try {
      final p = await AppContainer.profile1cApi
          .getMyProfile()
          .timeout(ApiConstants.prefetchRequestTimeout);
      await AppContainer.jsonCache.setJson('1c:my-profile', p.toJsonMap());
      if (mounted) setState(() => _oneC = p);
    } catch (_) {}

    try {
      final g = await AppContainer.groupsApi
          .getMyGroup()
          .timeout(ApiConstants.prefetchRequestTimeout);
      if (g != null) {
        await AppContainer.jsonCache.setJson('groups:my', g.toJson());
        if (mounted) setState(() => _group = g);
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingProfile = false);
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _isStudent {
    try {
      final c = AppContainer.jsonCache.getJsonMap('auth:me');
      if (c == null) return false;
      final r = '${c['role'] ?? ''}'.trim().toLowerCase();
      return r == 'student';
    } catch (_) {
      return false;
    }
  }

  String get _wifiLogin => (_me?.studentBookNumber ?? '').trim();

  String _courseDisplay() {
    int? c = _ticket?.course;
    c ??= _oneC?.course;
    c ??= _me?.course;
    if (c == null) return '—';
    return _formatCourseChip('$c');
  }

  String _groupDisplay() {
    final st = _ticket?.studyGroup?.trim();
    if (st != null && st.isNotEmpty) return st;
    final g1c = _oneC?.group?.trim();
    if (g1c != null && g1c.isNotEmpty) return g1c;
    final label = _group?.displayLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return '—';
  }

  static String _formatCourseChip(String raw) {
    final t = raw.trim();
    if (t.isEmpty || t == '-') return '—';
    final lower = t.toLowerCase();
    if (lower.contains('курс')) return t;
    final n = int.tryParse(t);
    if (n != null) return '$n курс';
    return '$t курс';
  }

  TextStyle _captionStyle() => AppTextStyle.inter(
        fontWeight: FontWeight.w600,
        fontSize: 9.67,
        height: 1.2,
        color: _labelBlue,
      );

  TextStyle _valueStyle() => AppTextStyle.inter(
        fontWeight: FontWeight.w800,
        fontSize: 14.38,
        height: 1.2,
        color: const Color(0xFF000000),
      );

  Widget _readonlyBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _captionStyle()),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1A000000)),
          ),
          child: Text(value, style: _valueStyle()),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final login = _wifiLogin;
    final pwd = _passwordCtrl.text.trim();

    setState(() => _fieldError = null);
    if (login.isEmpty) {
      setState(() {
        _fieldError =
            'В профиле нет номера зачётной книжки. Обновите данные или обратитесь в учебную часть.';
      });
      return;
    }
    if (pwd.length < 8) {
      setState(() => _fieldError = 'Пароль Wi‑Fi: не менее 8 символов');
      return;
    }

    setState(() => _submitting = true);
    try {
      final msg = await AppContainer.accountApi.requestStudentWifiPassword(
        wifiLogin: login,
        desiredPassword: pwd,
        courseGroupHint: null,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Заявка отправлена',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            msg,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 1.35,
              color: AppColors.grey,
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (context.mounted) context.pop();
              },
              child: Text(
                'Ок',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _fieldError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStudent) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppHeader(
          leading: appHeaderNestedBackLeading(context),
          headerTitle: Text(
            'Wi‑Fi',
            style: appHeaderNestedTitleStyle,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Заявка доступна только для студентов.',
              textAlign: TextAlign.center,
              style: AppTextStyle.inter(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text(
          'Пароль Wi‑Fi',
          style: appHeaderNestedTitleStyle,
        ),
      ),
      body: DismissKeyboardOnTap(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x332E63D5)),
              ),
              child: Text(
                'Заявка в учебный отдел на доступ к Wi‑Fi колледжа. '
                'Пароль входа в приложение не меняется.',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_loadingProfile) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              const SizedBox(height: 20),
              _readonlyBlock(
                'Логин для Wi‑Fi (номер студенческого билета)',
                _wifiLogin.isEmpty ? '—' : _wifiLogin,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _readonlyBlock('Курс', _courseDisplay()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _readonlyBlock('Группа', _groupDisplay()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Желаемый пароль Wi‑Fi',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 9.67,
                  height: 1.2,
                  color: _labelBlue,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                maxLength: 128,
                decoration: InputDecoration(
                  hintText: 'Минимум 8 символов',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0x38000000)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.caption,
                    ),
                  ),
                  counterText: '',
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(128),
                ],
              ),
              if (_fieldError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _fieldError!,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3,
                    color: const Color(0xFFC84547),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Отправить заявку',
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
