import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/models/user_model.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  bool _busy = false;
  String? _displayEmail;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEmail());
  }

  Future<void> _loadEmail() async {
    try {
      final c = AppContainer.jsonCache.getJsonMap('auth:me');
      if (c != null) {
        final e = UserModel.fromJson(c).email.trim();
        if (e.isNotEmpty && mounted) setState(() => _displayEmail = e);
      }
      final fresh = await AppContainer.authApi.getMe();
      await AppContainer.jsonCache.setJson('auth:me', fresh.toJson());
      if (!mounted) return;
      final e = fresh.email.trim();
      if (e.isNotEmpty) setState(() => _displayEmail = e);
    } catch (_) {}
  }

  Future<void> _requestSelf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AppContainer.accountApi.requestPasswordResetSelf();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ссылка для сброса отправлена на ваш e-mail')),
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

  @override
  Widget build(BuildContext context) {
    final email = _displayEmail;

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
            'Сброс по ссылке',
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
              'Мы отправим на ваш e-mail письмо со ссылкой для сброса пароля.',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                height: 18 / 13,
                color: AppColors.notificationSubtitle,
              ),
            ),
            if (email != null && email.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppUi.radiusM),
                ),
                child: Text(
                  email,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _busy ? null : _requestSelf,
              child: Text(_busy ? 'Отправляем…' : 'Отправить ссылку'),
            ),
            const SizedBox(height: 10),
            Text(
              'Если письма нет — проверьте «Спам» и попробуйте ещё раз через минуту.',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 16 / 12,
                color: AppColors.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
