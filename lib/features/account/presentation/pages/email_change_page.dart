import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';

class EmailChangePage extends StatefulWidget {
  const EmailChangePage({super.key});

  @override
  State<EmailChangePage> createState() => _EmailChangePageState();
}

class _EmailChangePageState extends State<EmailChangePage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _requested = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Мы отправили код на новый адрес')),
      );
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
    final code = _codeCtrl.text.trim();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            'Смена E-mail',
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 24 / 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Введите новый E-mail. Для подтверждения введите код из письма, отправленный на старый E-mail.',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                height: 18 / 13,
                color: AppColors.notificationSubtitle,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUi.radiusM),
                  borderSide: BorderSide.none,
                ),
                hintText: 'new@email.ru',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _request,
              child: Text(_requested ? 'Отправить код ещё раз' : 'Отправить код'),
            ),
            const SizedBox(height: 18),
            if (_requested) ...[
              Text(
                'Код подтверждения',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.caption,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppUi.radiusM),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Например, 123456',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _confirm,
                child: const Text('Подтвердить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

