import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/models/user_model.dart';
import '../../../../shared/widgets/app_header.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  bool _busy = false;
  String? _displayEmail;
  Timer? _cooldownTimer;
  int _cooldownLeftSec = 0;
  bool _sentOnce = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEmail());
    unawaited(_loadCooldown());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
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

  Future<void> _loadCooldown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final untilMs = prefs.getInt(AppConstants.passwordResetCooldownUntilMsKey) ?? 0;
      final left = ((untilMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (!mounted) return;
      if (left > 0) {
        setState(() => _cooldownLeftSec = left);
        _startCooldownTicker();
      } else {
        setState(() => _cooldownLeftSec = 0);
      }
    } catch (_) {}
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final next = _cooldownLeftSec - 1;
      if (next <= 0) {
        setState(() => _cooldownLeftSec = 0);
        _cooldownTimer?.cancel();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(AppConstants.passwordResetCooldownUntilMsKey);
        } catch (_) {}
      } else {
        setState(() => _cooldownLeftSec = next);
      }
    });
  }

  Future<void> _setCooldown60s() async {
    final untilMs = DateTime.now().millisecondsSinceEpoch + 60 * 1000;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.passwordResetCooldownUntilMsKey, untilMs);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _cooldownLeftSec = 60);
    _startCooldownTicker();
  }

  Future<void> _requestSelf() async {
    if (_busy) return;
    if (_cooldownLeftSec > 0) return;
    setState(() => _busy = true);
    try {
      await AppContainer.accountApi.requestPasswordResetSelf();
      if (!mounted) return;
      setState(() => _sentOnce = true);
      await _setCooldown60s();
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

  String _cooldownLabel() {
    final s = _cooldownLeftSec;
    if (s <= 0) return 'Сбросить';
    return 'Сбросить (${s}с)';
  }

  @override
  Widget build(BuildContext context) {
    final email = _displayEmail;
    final canTap = !_busy && _cooldownLeftSec <= 0;
    final showSpamHint = _sentOnce || _cooldownLeftSec > 0;

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
          'Сброс по ссылке',
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
            SizedBox(
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
                child: Text(
                  (email == null || email.isEmpty) ? '—' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.0,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/account/email-change'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Сменить почту',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.0,
                      color: const Color(0xFF2E63D5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 35,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canTap ? _requestSelf : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: canTap ? const Color(0xFF2E63D5) : const Color(0xFF2E63D5).withValues(alpha: 0.4),
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
                          _cooldownLabel(),
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.0,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              showSpamHint
                  ? 'Если письма нет - проверьте "Спам" и попробуйте еще раз через минуту.'
                  : 'Мы отправим на ваш e-mail письмо со ссылкой для сброса пароля.',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.2,
                color: const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
