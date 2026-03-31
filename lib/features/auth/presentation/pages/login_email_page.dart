import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';

/// Экран входа/регистрации по E-mail.
/// Визуально повторяет стиль входа по зачётке.
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

  bool _hasText(TextEditingController c) => c.text.trim().isNotEmpty;

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

  String get _topTitle {
    if (_isParentRole) return 'Родитель';
    return _isRegisterMode ? 'Регистрация' : 'Студент';
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
      // Как при холодном старте: прогрев кэша под тем же пользователем.
      context.go('/bootstrap');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _showWrongCredentialsError = true;
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
    const figmaW = 1080.0;
    const figmaH = 1920.0;
    final size = MediaQuery.sizeOf(context);
    final sf = math.min(size.width / figmaW, size.height / figmaH);
    final blue = const Color.fromRGBO(46, 99, 213, 1);

    final fieldRadius = 89.16 * sf;
    final fieldBorderW = (4.46 * sf).clamp(2.0, 6.0);
    // Поля должны быть той же высоты, что и кнопки.
    final fieldHeight = (120.0 * sf).clamp(56.0, 140.0);
    final fieldLeftPad = 75.0 * sf;
    final sidePad = 40.0 * sf;
    final gap = (10.0 * sf).clamp(6.0, 14.0);

    final hintStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 35.84 * sf,
      height: (55.75 / 35.84),
      color: Colors.black.withValues(alpha: 0.24),
    );
    final valueStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 35.84 * sf,
      height: (55.75 / 35.84),
      color: Colors.black,
    );

    final btnRadius = 117.96 * sf;
    final btnBorder = (7.07 * sf).clamp(3.0, 10.0);
    final btnTextStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 45.47 * sf,
      height: 1.0,
    );
    final btnHeight = fieldHeight;

    final noTapFxTheme = Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );

    ButtonStyle noOverlay(ButtonStyle base) {
      return base.copyWith(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      );
    }

    return PopScope(
      canPop: false,
      child: Theme(
        data: noTapFxTheme,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Expanded(
                flex: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/photo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: Colors.black12),
                    ),
                    Positioned(
                      left: 60 * sf,
                      top: 90 * sf,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _topTitle,
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 111.73 * sf,
                              height: 1.0,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10 * sf),
                          Text(
                            'КОЛЛЕДЖ ДГУ',
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 32.96 * sf * 1.25,
                              height: 1.0,
                              letterSpacing: -0.82 * sf * 1.25,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 60 * sf,
                      bottom: 36 * sf,
                      child: SizedBox(
                        width: 126 * sf * 1.5,
                        height: 126 * sf * 1.5,
                        child: SvgPicture.asset(
                          'assets/icons/logo.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final content = ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 900 * sf),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildField(
                              key: 'email',
                              hint: 'E-mail',
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              fieldHeight: fieldHeight,
                              fieldRadius: fieldRadius,
                              fieldBorderW: fieldBorderW,
                              fieldLeftPad: fieldLeftPad,
                              blue: blue,
                              hintStyle: hintStyle,
                              valueStyle: valueStyle,
                              obscureText: false,
                            ),
                            SizedBox(height: gap),
                            _buildField(
                              key: 'password',
                              hint: 'Пароль',
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              keyboardType: TextInputType.visiblePassword,
                              fieldHeight: fieldHeight,
                              fieldRadius: fieldRadius,
                              fieldBorderW: fieldBorderW,
                              fieldLeftPad: fieldLeftPad,
                              blue: blue,
                              hintStyle: hintStyle,
                              valueStyle: valueStyle,
                              obscureText: true,
                            ),
                            SizedBox(height: gap),
                            if (_showWrongCredentialsError) ...[
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
                              SizedBox(height: gap),
                            ],
                            SizedBox(
                              height: btnHeight,
                              child: FilledButton(
                                onPressed: _submitting ? null : _submit,
                                style: noOverlay(FilledButton.styleFrom(
                                  backgroundColor: blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(btnRadius),
                                  ),
                                  fixedSize: Size.fromHeight(btnHeight),
                                  minimumSize: Size(double.infinity, btnHeight),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  textStyle: btnTextStyle,
                                )),
                                child: Center(child: Text(_submitting ? 'Входим…' : 'Войти')),
                              ),
                            ),
                            SizedBox(height: gap),
                            if (!_isParentRole)
                              SizedBox(
                                height: btnHeight,
                                child: OutlinedButton(
                                  onPressed: () => context.go('/login/student'),
                                  style: noOverlay(OutlinedButton.styleFrom(
                                    foregroundColor: blue,
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(color: blue, width: btnBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(btnRadius),
                                    ),
                                    fixedSize: Size.fromHeight(btnHeight),
                                    minimumSize: Size(double.infinity, btnHeight),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    textStyle: btnTextStyle,
                                  )),
                                  child: Center(
                                    child: Text(_isRegisterMode ? 'Назад' : 'Войти по зачетной книжке'),
                                  ),
                                ),
                              ),
                            if (_isParentRole && !_isRegisterMode) ...[
                              SizedBox(height: gap),
                              SizedBox(
                                height: btnHeight,
                                child: OutlinedButton(
                                  onPressed: () => context.go('/login/student'),
                                  style: noOverlay(OutlinedButton.styleFrom(
                                    foregroundColor: blue,
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(color: blue, width: btnBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(btnRadius),
                                    ),
                                    fixedSize: Size.fromHeight(btnHeight),
                                    minimumSize: Size(double.infinity, btnHeight),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    textStyle: btnTextStyle,
                                  )),
                                  child: const Center(child: Text('Войти как студент')),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(sidePad, 18 * sf, sidePad, 18 * sf),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: Center(child: content),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String key,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextInputType keyboardType,
    required double fieldHeight,
    required double fieldRadius,
    required double fieldBorderW,
    required double fieldLeftPad,
    required Color blue,
    required TextStyle hintStyle,
    required TextStyle valueStyle,
    required bool obscureText,
  }) {
    final hasError = _errorFields.contains(key);
    final hasValue = _hasText(controller);
    final baseColor = Colors.black.withValues(alpha: 0.22);
    final enabledColor = hasValue ? Colors.black : baseColor;
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(
        color: hasError ? Colors.red : enabledColor,
        width: fieldBorderW,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(
        color: hasError ? Colors.red : blue,
        width: fieldBorderW,
      ),
    );

    return SizedBox(
      height: fieldHeight,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        inputFormatters: [
          if (key == 'email') FilteringTextInputFormatter.deny(RegExp(r'\s')),
        ],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: hintStyle,
          filled: false,
          border: enabledBorder,
          enabledBorder: enabledBorder,
          focusedBorder: focusedBorder,
          errorBorder: enabledBorder.copyWith(
            borderSide: BorderSide(color: Colors.red, width: fieldBorderW),
          ),
          focusedErrorBorder: focusedBorder.copyWith(
            borderSide: BorderSide(color: Colors.red, width: fieldBorderW),
          ),
          contentPadding: EdgeInsets.only(
            left: fieldLeftPad,
            right: 24,
            top: 0,
            bottom: 0,
          ),
          errorText: null,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          counterText: '',
        ),
        style: valueStyle,
        onChanged: (_) {
          if (mounted) setState(() {});
        },
      ),
    );
  }
}

