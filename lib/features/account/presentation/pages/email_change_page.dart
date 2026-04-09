import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/models/user_model.dart';
import '../../../../shared/widgets/app_header.dart';

class EmailChangePage extends StatefulWidget {
  const EmailChangePage({super.key});

  @override
  State<EmailChangePage> createState() => _EmailChangePageState();
}

class _EmailChangePageState extends State<EmailChangePage> {
  final _emailCtrl = TextEditingController();

  final List<TextEditingController> _codeCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocus =
      List.generate(6, (_) => FocusNode());

  bool _requested = false;
  bool _busy = false;
  String? _oldEmail;

  @override
  void initState() {
    super.initState();
    unawaited(_loadOldEmail());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _codeCtrls) {
      c.dispose();
    }
    for (final f in _codeFocus) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOldEmail() async {
    try {
      final c = AppContainer.jsonCache.getJsonMap('auth:me');
      if (c != null) {
        final e = UserModel.fromJson(c).email.trim();
        if (e.isNotEmpty && mounted) setState(() => _oldEmail = e);
      }
      final fresh = await AppContainer.authApi.getMe();
      await AppContainer.jsonCache.setJson('auth:me', fresh.toJson());
      if (!mounted) return;
      final e = fresh.email.trim();
      if (e.isNotEmpty) setState(() => _oldEmail = e);
    } catch (_) {}
  }

  Future<void> _request() async {
    if (_busy) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    try {
      await AppContainer.accountApi.requestEmailChange(newEmail: email);
      if (!mounted) return;
      setState(() => _requested = true);
      // Focus first code box.
      unawaited(Future<void>.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _codeFocus.first.requestFocus();
      }));
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? e.message : 'Ошибка';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final email = _emailCtrl.text.trim();
    final code = _codeCtrls.map((c) => c.text.trim()).join();
    if (email.isEmpty || code.isEmpty) return;
    setState(() => _busy = true);
    try {
      await AppContainer.accountApi.confirmEmailChange(newEmail: email, code: code);
      try {
        final me = await AppContainer.authApi.getMe();
        await AppContainer.jsonCache.setJson('auth:me', me.toJson());
        await AppContainer.tokenStorage.setUserDataJson(jsonEncode(me.toJson()));
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Адрес e-mail обновлён')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? e.message : 'Ошибка';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _emailField() {
    return SizedBox(
      height: 44,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF000000), width: 1.5),
        ),
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
            border: InputBorder.none,
            hintText: 'new@email.ru',
          ),
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.0,
            color: Color(0xFF000000),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback? onTap}) {
    final enabled = onTap != null && !_busy;
    return SizedBox(
      height: 35,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF2E63D5) : const Color(0xFF2E63D5).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  void _onCodeChanged(int idx, String v) {
    final t = v.trim();
    if (t.length > 1) {
      _codeCtrls[idx].text = t.substring(t.length - 1);
      _codeCtrls[idx].selection = const TextSelection.collapsed(offset: 1);
    }
    if (t.isNotEmpty && idx < _codeFocus.length - 1) {
      _codeFocus[idx + 1].requestFocus();
    }
    if (_codeCtrls.every((c) => c.text.trim().isNotEmpty)) {
      unawaited(_confirm());
    }
  }

  Widget _codeBox(int idx) {
    final focused = _codeFocus[idx].hasFocus;
    return Focus(
      onFocusChange: (_) {
        if (mounted) setState(() {});
      },
      child: SizedBox(
        width: 50,
        height: 64,
        child: TextField(
          controller: _codeCtrls[idx],
          focusNode: _codeFocus[idx],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: focused ? const Color(0x0F2563EB) : Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: focused ? const Color(0xFF2563EB) : const Color(0xFF000000),
                width: focused ? 1 : 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF000000), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            height: 1.0,
            color: const Color(0xFF000000),
          ),
          onChanged: (v) => _onCodeChanged(idx, v),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leadingLeftPadding: 6,
        leading: GestureDetector(
          onTap: () => context.pop(),
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        headerTitle: Text(
          'Смена E-mail',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 24 / 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_requested) ...[
              _emailField(),
              const SizedBox(height: 12),
              _primaryButton(label: 'Отправить код', onTap: _request),
              const SizedBox(height: 10),
              Text(
                'Введите новый e-mail. Для подтверждения введите код из письма, отправленный на старый e-mail.',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                  color: const Color(0xFF000000),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 6; i++) ...[
                    _codeBox(i),
                    if (i != 5) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  text: 'Введите код отправленный на почту',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.2,
                    color: const Color(0xFF000000),
                  ),
                  children: [
                    if (_oldEmail != null && _oldEmail!.trim().isNotEmpty)
                      TextSpan(
                        text: ' ${_oldEmail!.trim()}',
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

