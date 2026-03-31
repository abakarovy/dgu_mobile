import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';

/// Экран входа по E-Mail: те же заголовок и оформление, поля E-Mail и Пароль, кнопка «Войти» и «Войти по № з/к».
class LoginEmailPage extends StatefulWidget {
  const LoginEmailPage({super.key, this.extra});

  final Object? extra;

  @override
  State<LoginEmailPage> createState() => _LoginEmailPageState();
}

class _LoginEmailPageState extends State<LoginEmailPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final Set<String> _errorFields = {};
  bool _showWrongCredentialsError = false;
  String _credentialsErrorMessage = 'Неверный E-Mail или пароль';
  bool _submitting = false;

  bool get _isRegisterMode {
    final e = widget.extra;
    return e is Map && e['mode'] == 'register';
  }

  bool get _isParentRole {
    final e = widget.extra;
    return e is Map && e['role'] == 'parent';
  }

  String? get _verifiedFullName {
    final e = widget.extra;
    if (e is Map) return e['fullName'] as String?;
    return null;
  }

  String? get _verifiedBookNumber {
    final e = widget.extra;
    if (e is Map) return e['book'] as String?;
    return null;
  }

  String? get _registrationToken {
    final e = widget.extra;
    if (e is Map) return e['registrationToken'] as String?;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        setState(() {
          _errorFields.remove('email');
          _showWrongCredentialsError = false;
        });
      }
    });
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() {
          _errorFields.remove('password');
          _showWrongCredentialsError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final errors = <String>{};
    if (_emailController.text.trim().isEmpty) errors.add('email');
    if (_passwordController.text.trim().isEmpty) errors.add('password');
    setState(() {
      _errorFields
        ..clear()
        ..addAll(errors);
      _showWrongCredentialsError = false;
    });
    if (errors.isNotEmpty) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      setState(() => _submitting = true);
      if (_isRegisterMode) {
        final fullName = _verifiedFullName;
        final book = _verifiedBookNumber;
        if (fullName == null || book == null) {
          throw ApiException('Ошибка');
        }
        await AppContainer.authRepository.registerStudent(
          fullName: fullName,
          studentBookNumber: book,
          email: email,
          password: password,
          registrationToken: _registrationToken,
        );
      } else {
        await AppContainer.authRepository.login(username: email, password: password);
      }
      if (!mounted) return;
      // Как при холодном старте: прогрев кэша под тем же пользователем, иначе главная читает старый JsonCache.
      context.go('/bootstrap');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _showWrongCredentialsError = true;
        // Если пытались зарегистрировать студента, а он уже зарегистрирован — просим вход по email.
        if (_isRegisterMode && (e.statusCode == 400 || e.statusCode == 409)) {
          _credentialsErrorMessage = 'Аккаунт уже существует. Войдите по E‑Mail.';
        } else {
          _credentialsErrorMessage = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final paddingH = width > 0 ? (AppUi.screenPaddingH * width / 448).clamp(16.0, 32.0) : AppUi.screenPaddingH;

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(paddingH, 32, paddingH, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIconBox(),
              const SizedBox(height: AppUi.spacingXl),
              Center(
                child: Text(
                  'Вход в систему',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    height: 32 / 24,
                    color: AppColors.loginPrimary,
                  ),
                ),
              ),
              Center(
                child: Text(
                  _isRegisterMode ? 'Регистрация по E‑Mail' : 'Введите ваши данные для входа',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppColors.notificationSubtitle,
                  ),
                ),
              ),
              const SizedBox(height: AppUi.spacingXl),
              _buildForm(),
              if (_showWrongCredentialsError) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _credentialsErrorMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 1.2,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 12),
              _buildSwitchButton(
                label: _isRegisterMode
                    ? 'Назад'
                    : (_isParentRole ? 'Назад' : 'Войти по № з/к'),
                onTap: () => context.go(_isParentRole ? '/login' : '/login/student'),
              ),
              if (_isParentRole && !_isRegisterMode) ...[
                const SizedBox(height: 8),
                _buildSwitchButton(
                  label: 'Войти как студент',
                  onTap: () => context.go('/login/student'),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildIconBox() {
    return Center(
      child: Container(
        width: AppUi.loginIconBoxSize,
        height: AppUi.loginIconBoxSize,
        decoration: BoxDecoration(
          color: AppColors.loginPrimary,
          borderRadius: BorderRadius.circular(AppUi.loginIconBoxRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.loginPrimary.withValues(alpha: 0.2),
              offset: const Offset(0, 8),
              blurRadius: 10,
              spreadRadius: -6,
            ),
            BoxShadow(
              color: AppColors.loginPrimary.withValues(alpha: 0.2),
              offset: const Offset(0, 20),
              blurRadius: 25,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/teach.svg',
            width: AppUi.loginIconSize,
            height: AppUi.loginIconSize,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(key: 'email', label: 'E-Mail', hint: 'example@mail.ru', controller: _emailController, focusNode: _emailFocusNode, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildField(key: 'password', label: 'Пароль', hint: '••••••••', controller: _passwordController, focusNode: _passwordFocusNode, obscureText: true),
        ],
      ),
    );
  }

  Widget _buildField({
    required String key,
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    final hasError = _errorFields.contains(key);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppUi.radiusM),
      borderSide: BorderSide.none,
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppUi.radiusM),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            height: 15 / 10,
            letterSpacing: 1,
            color: AppColors.notificationSubtitle,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyle.inter(
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.0,
              color: AppColors.textPrimary.withValues(alpha: 0.45),
            ),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            border: border,
            enabledBorder: hasError ? errorBorder : border,
            focusedBorder: hasError ? errorBorder : border,
            errorBorder: errorBorder,
            focusedErrorBorder: errorBorder,
            contentPadding: const EdgeInsets.all(16),
            errorText: null,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.0,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _submit,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.loginPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUi.radiusL),
        ),
        textStyle: AppTextStyle.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          height: 24 / 16,
        ),
      ),
      child: Text(_isRegisterMode ? 'Зарегистрироваться' : 'Войти'),
    );
  }

  Widget _buildSwitchButton({required String label, required VoidCallback onTap}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.loginPrimary,
        textStyle: AppTextStyle.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 20 / 14,
        ),
      ),
      child: Text(label),
    );
  }
}
