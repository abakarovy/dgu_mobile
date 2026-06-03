import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../shared/widgets/dismiss_keyboard_on_tap.dart';
import '../../domain/auth_flow_results.dart';
import '../registration_support_flow.dart';
import '../widgets/login_photo_hero_header.dart';

/// Вход / регистрация по E-mail — те же поля и кнопки, что на экране «Студент».
class LoginEmailPage extends StatefulWidget {
  const LoginEmailPage({super.key, this.extra});

  final Object? extra;

  @override
  State<LoginEmailPage> createState() => _LoginEmailPageState();
}

class _LoginEmailPageState extends State<LoginEmailPage> {
  static const Color _kBlue = Color(0xFF2E63D5);
  static const Color _kBorderMuted = Color(0x38000000);
  static const Color _kBorderFilled = Color(0xFF000000);

  static const double _formHorizontalInset = 30;
  static const double _fieldH = 60;
  static const double _radius = 46;
  static const double _inputLineHeight = 22;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  final Set<String> _errorFields = {};
  bool _showWrongCredentialsError = false;
  String _credentialsErrorMessage = 'Неверный E-Mail или пароль';
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _forgotBusy = false;
  Timer? _forgotCooldownTimer;
  int _forgotCooldownLeft = 0;

  bool _awaitingOtp = false;
  bool _otpIsForRegister = false;
  OtpChallenge? _otpChallenge;
  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  Object? get _extra => widget.extra;

  bool get _isRegisterMode {
    final e = _extra;
    return e is Map && e['mode'] == 'register';
  }

  bool get _isParentRole {
    final e = _extra;
    return e is Map && e['role'] == 'parent';
  }

  String? get _verifiedFullName {
    final e = _extra;
    if (e is Map) return e['fullName'] as String?;
    return null;
  }

  String? get _verifiedBookNumber {
    final e = _extra;
    if (e is Map) return e['book'] as String?;
    return null;
  }

  String? get _registrationToken {
    final e = _extra;
    if (e is Map) return e['registrationToken'] as String?;
    return null;
  }

  String get _topTitle {
    if (_isParentRole) return 'Родитель';
    return _isRegisterMode ? 'Регистрация' : 'Студент';
  }

  Future<void> _handleRegisterApiException(ApiException e) async {
    if (!mounted) return;
    final fullName = _verifiedFullName;
    final book = _verifiedBookNumber;
    if (fullName == null || book == null) {
      setState(() {
        _showWrongCredentialsError = true;
        _credentialsErrorMessage = e.message;
      });
      return;
    }
    if (isStudentBookNotFoundRegistrationError(
      message: e.message,
      statusCode: e.statusCode,
    )) {
      await showRegistrationBookNotFoundDialog(
        context: context,
        errorMessage: e.message,
        fullName: fullName,
        studentBookNumber: book,
        source: 'student/register',
        registrationEmail: _emailController.text.trim(),
        dialogTitle: 'Не удалось зарегистрироваться',
      );
      return;
    }
    setState(() {
      _showWrongCredentialsError = true;
      if (e.statusCode == 400 || e.statusCode == 409) {
        _credentialsErrorMessage =
            'Аккаунт уже существует. Войдите по E‑Mail.';
      } else {
        _credentialsErrorMessage = e.message;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    void refresh() {
      if (mounted) setState(() {});
    }

    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus && mounted) {
        setState(() {
          _errorFields.remove('email');
          _showWrongCredentialsError = false;
        });
      }
      refresh();
    });
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus && mounted) {
        setState(() {
          _errorFields.remove('password');
          _showWrongCredentialsError = false;
        });
      }
      refresh();
    });
    _otpFocusNode.addListener(() {
      if (_otpFocusNode.hasFocus && mounted) {
        setState(() {
          _errorFields.remove('otp');
          _showWrongCredentialsError = false;
        });
      }
      refresh();
    });
    _emailController.addListener(refresh);
    _passwordController.addListener(refresh);
    _otpController.addListener(refresh);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _forgotCooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startForgotCooldown(int seconds) {
    _forgotCooldownTimer?.cancel();
    setState(() => _forgotCooldownLeft = seconds.clamp(0, 3600));
    _forgotCooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_forgotCooldownLeft <= 1) {
          _forgotCooldownTimer?.cancel();
          _forgotCooldownLeft = 0;
        } else {
          _forgotCooldownLeft--;
        }
      });
    });
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = seconds.clamp(0, 3600));
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendSecondsLeft <= 1) {
          _resendTimer?.cancel();
          _resendSecondsLeft = 0;
        } else {
          _resendSecondsLeft--;
        }
      });
    });
  }

  void _leaveOtpStep() {
    _resendTimer?.cancel();
    setState(() {
      _awaitingOtp = false;
      _otpChallenge = null;
      _otpIsForRegister = false;
      _otpController.clear();
      _resendSecondsLeft = 0;
      _showWrongCredentialsError = false;
    });
  }

  Future<void> _resendOtp() async {
    if (_submitting || _resendSecondsLeft > 0) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    try {
      setState(() => _submitting = true);
      if (_otpIsForRegister) {
        final fullName = _verifiedFullName;
        final book = _verifiedBookNumber;
        if (fullName == null || book == null) return;
        final r = await AppContainer.authRepository.registerStudent(
          fullName: fullName,
          studentBookNumber: book,
          email: email,
          password: password,
          registrationToken: _registrationToken,
        );
        if (!mounted) return;
        switch (r) {
          case AuthRegisterSuccess():
            context.go('/bootstrap');
            return;
          case AuthRegisterNeedsOtp(:final challenge):
            setState(() {
              _otpChallenge = challenge;
              _startResendCooldown(challenge.resendAfterSeconds);
            });
        }
      } else {
        final r = await AppContainer.authRepository.login(
          username: email,
          password: password,
        );
        if (!mounted) return;
        switch (r) {
          case AuthLoginSuccess():
            context.go('/bootstrap');
            return;
          case AuthLoginNeedsOtp(:final challenge):
            setState(() {
              _otpChallenge = challenge;
              _startResendCooldown(challenge.resendAfterSeconds);
            });
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_otpIsForRegister) {
        await _handleRegisterApiException(e);
      } else {
        setState(() {
          _showWrongCredentialsError = true;
          _credentialsErrorMessage = e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Color _borderColor(FocusNode fn, TextEditingController c) {
    if (fn.hasFocus) return _kBlue;
    if (c.text.trim().isNotEmpty) return _kBorderFilled;
    return _kBorderMuted;
  }

  Color _borderColorForKey(String key) {
    if (key == 'email') {
      return _borderColor(_emailFocusNode, _emailController);
    }
    if (key == 'password') {
      return _borderColor(_passwordFocusNode, _passwordController);
    }
    if (key == 'otp') {
      return _borderColor(_otpFocusNode, _otpController);
    }
    return _kBorderMuted;
  }

  ButtonStyle _noOverlay(ButtonStyle base) {
    return base.copyWith(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  Widget _outlineField({
    required String key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    FocusNode? nextFocus,
    VoidCallback? onLastSubmitted,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
  }) {
    final isLast = nextFocus == null;
    final hasErr = _errorFields.contains(key);
    final borderColor = hasErr ? Colors.red : _borderColorForKey(key);

    final hintStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.0,
      color: _kBorderMuted,
    );
    final textStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.0,
      color: _kBorderFilled,
    );
    final verticalPad = (_fieldH - _inputLineHeight) / 2;

    return SizedBox(
      height: _fieldH,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.ltr,
                  textInputAction: isLast
                      ? TextInputAction.done
                      : TextInputAction.next,
                  inputFormatters: inputFormatters,
                  obscureText: obscureText,
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: 1,
                  minLines: 1,
                  style: textStyle,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: hintStyle,
                    hintTextDirection: TextDirection.ltr,
                    alignLabelWithHint: true,
                    border: InputBorder.none,
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.fromLTRB(
                      0,
                      verticalPad,
                      0,
                      verticalPad,
                    ),
                    counterText: '',
                  ),
                  onSubmitted: (_) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (isLast) {
                        onLastSubmitted?.call();
                      } else {
                        nextFocus.requestFocus();
                      }
                    });
                  },
                ),
              ),
              if (onToggleObscure != null) ...[
                IconButton(
                  onPressed: onToggleObscure,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_awaitingOtp) {
      final code = _otpController.text.trim();
      final errors = <String>{};
      if (code.length != 6) errors.add('otp');
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
        if (_otpIsForRegister) {
          final fullName = _verifiedFullName;
          final book = _verifiedBookNumber;
          if (fullName == null || book == null) {
            throw ApiException('Ошибка');
          }
          final r = await AppContainer.authRepository.registerStudent(
            fullName: fullName,
            studentBookNumber: book,
            email: email,
            password: password,
            registrationToken: _registrationToken,
            otpCode: code,
          );
          if (!mounted) return;
          switch (r) {
            case AuthRegisterSuccess():
              context.go('/bootstrap');
            case AuthRegisterNeedsOtp(:final challenge):
              setState(() {
                _otpChallenge = challenge;
                _startResendCooldown(challenge.resendAfterSeconds);
              });
          }
        } else {
          final r = await AppContainer.authRepository.login(
            username: email,
            password: password,
            otpCode: code,
          );
          if (!mounted) return;
          switch (r) {
            case AuthLoginSuccess():
              context.go('/bootstrap');
            case AuthLoginNeedsOtp(:final challenge):
              setState(() {
                _otpChallenge = challenge;
                _startResendCooldown(challenge.resendAfterSeconds);
              });
          }
        }
      } on ApiException catch (e) {
        if (!mounted) return;
        if (_otpIsForRegister) {
          await _handleRegisterApiException(e);
        } else {
          setState(() {
            _showWrongCredentialsError = true;
            _credentialsErrorMessage = e.message;
          });
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

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
        final r = await AppContainer.authRepository.registerStudent(
          fullName: fullName,
          studentBookNumber: book,
          email: email,
          password: password,
          registrationToken: _registrationToken,
        );
        if (!mounted) return;
        switch (r) {
          case AuthRegisterSuccess():
            context.go('/bootstrap');
          case AuthRegisterNeedsOtp(:final challenge):
            setState(() {
              _awaitingOtp = true;
              _otpIsForRegister = true;
              _otpChallenge = challenge;
              _startResendCooldown(challenge.resendAfterSeconds);
            });
        }
      } else {
        final r = await AppContainer.authRepository.login(
          username: email,
          password: password,
        );
        if (!mounted) return;
        switch (r) {
          case AuthLoginSuccess():
            context.go('/bootstrap');
          case AuthLoginNeedsOtp(:final challenge):
            setState(() {
              _awaitingOtp = true;
              _otpIsForRegister = false;
              _otpChallenge = challenge;
              _startResendCooldown(challenge.resendAfterSeconds);
            });
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_isRegisterMode) {
        await _handleRegisterApiException(e);
      } else {
        setState(() {
          _showWrongCredentialsError = true;
          _credentialsErrorMessage = e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showAppAlert({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              height: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            message,
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
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_radius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Ок',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorFields
          ..clear()
          ..add('email');
        _showWrongCredentialsError = false;
      });
      _emailFocusNode.requestFocus();
      await _showAppAlert(
        title: 'Восстановление пароля',
        message:
            'Введите e-mail в поле выше, затем снова нажмите «Забыли пароль».',
      );
      return;
    }
    if (_forgotBusy || _forgotCooldownLeft > 0) return;
    try {
      setState(() => _forgotBusy = true);
      final apiMessage = await AppContainer.accountApi.requestPasswordReset(
        email: email,
      );
      if (!mounted) return;
      await _showAppAlert(
        title: 'Восстановление пароля',
        message:
            apiMessage ??
            'Если этот адрес зарегистрирован в системе, на него отправлена ссылка для смены пароля.',
      );
      if (!mounted) return;
      _startForgotCooldown(60);
    } on ApiException catch (e) {
      if (!mounted) return;
      await _showAppAlert(title: 'Ошибка', message: e.message);
    } finally {
      if (mounted) setState(() => _forgotBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const figmaW = 1080.0;
    const figmaH = 1920.0;
    final size = MediaQuery.sizeOf(context);
    final sf = math.min(size.width / figmaW, size.height / figmaH);
    final safeTop = MediaQuery.paddingOf(context).top;
    const photoFlex = 2;
    const formFlex = 4;

    final noTapFxTheme = Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );

    final btnLabel = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.0,
      color: Colors.white,
    );

    final linkStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 1.0,
      color: _kBlue,
    );

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Theme(
          data: noTapFxTheme,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: DismissKeyboardOnTap(
              child: Column(
                children: [
                  Expanded(
                    flex: photoFlex,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/photo.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: Colors.black12),
                        ),
                        Positioned(
                          left: 0,
                          top: safeTop + 8,
                          right: 60 * sf,
                          child: LoginPhotoHeroHeader(
                            sf: sf,
                            title: _topTitle,
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
                    flex: formFlex,
                    child: SafeArea(
                      top: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              _formHorizontalInset,
                              16,
                              _formHorizontalInset,
                              16,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 32,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_showWrongCredentialsError) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
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
                                  if (_awaitingOtp &&
                                      _otpChallenge != null) ...[
                                    Text(
                                      _otpChallenge!.message,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyle.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        height: 1.3,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if ((_otpChallenge!.emailMasked ?? '')
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Код отправлен на ${_otpChallenge!.emailMasked}',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyle.inter(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          height: 1.25,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    _outlineField(
                                      key: 'otp',
                                      controller: _otpController,
                                      focusNode: _otpFocusNode,
                                      hint: 'Код из письма (6 цифр)',
                                      onLastSubmitted: _submit,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(6),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: _fieldH,
                                      child: FilledButton(
                                        onPressed: _submitting ? null : _submit,
                                        style: _noOverlay(
                                          FilledButton.styleFrom(
                                            backgroundColor: _kBlue,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: _kBlue
                                                .withValues(alpha: 0.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    _radius,
                                                  ),
                                            ),
                                            padding: EdgeInsets.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            elevation: 0,
                                          ),
                                        ),
                                        child: _submitting
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Text(
                                                'Подтвердить',
                                                style: btnLabel,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed:
                                          (_submitting ||
                                              _resendSecondsLeft > 0)
                                          ? null
                                          : _resendOtp,
                                      child: Text(
                                        _resendSecondsLeft > 0
                                            ? 'Отправить снова через $_resendSecondsLeft с'
                                            : 'Отправить код снова',
                                        style: AppTextStyle.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _kBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: _fieldH,
                                      child: OutlinedButton(
                                        onPressed: _submitting
                                            ? null
                                            : _leaveOtpStep,
                                        style: _noOverlay(
                                          OutlinedButton.styleFrom(
                                            foregroundColor: _kBlue,
                                            side: const BorderSide(
                                              color: _kBlue,
                                              width: 1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    _radius,
                                                  ),
                                            ),
                                            padding: EdgeInsets.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                        child: Text(
                                          'Назад к паролю',
                                          style: AppTextStyle.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: _kBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    _outlineField(
                                      key: 'email',
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      hint: 'E-mail',
                                      nextFocus: _passwordFocusNode,
                                      keyboardType: TextInputType.emailAddress,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(
                                          RegExp(r'\s'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _outlineField(
                                      key: 'password',
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      hint: 'Пароль',
                                      onLastSubmitted: _submit,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      obscureText: _obscurePassword,
                                      onToggleObscure: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    if (!_isRegisterMode) ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: _forgotCooldownLeft > 0
                                              ? Text(
                                                  'Отправить снова через $_forgotCooldownLeft с',
                                                  textAlign: TextAlign.right,
                                                  style: AppTextStyle.inter(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    height: 1.0,
                                                    color: _kBlue,
                                                  ),
                                                )
                                              : _forgotBusy
                                              ? SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        color: _kBlue,
                                                      ),
                                                )
                                              : GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: _requestForgotPassword,
                                                  child: Text(
                                                    'Забыли пароль',
                                                    style: AppTextStyle.inter(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                      height: 1.0,
                                                      color: _kBlue,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: _fieldH,
                                      child: FilledButton(
                                        onPressed: _submitting ? null : _submit,
                                        style: _noOverlay(
                                          FilledButton.styleFrom(
                                            backgroundColor: _kBlue,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: _kBlue
                                                .withValues(alpha: 0.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    _radius,
                                                  ),
                                            ),
                                            padding: EdgeInsets.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            elevation: 0,
                                          ),
                                        ),
                                        child: _submitting
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Text(
                                                _isRegisterMode
                                                    ? 'Зарегистрироваться'
                                                    : 'Войти',
                                                style: btnLabel,
                                              ),
                                      ),
                                    ),
                                    if (_isParentRole) ...[
                                      if (!_isRegisterMode) ...[
                                        const SizedBox(height: 24),
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => context.go(
                                            '/login/email',
                                            extra: const {
                                              'role': 'student',
                                              'mode': 'login',
                                            },
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: Text(
                                              'Войти как студент',
                                              textAlign: TextAlign.center,
                                              style: linkStyle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ] else ...[
                                      const SizedBox(height: 24),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            context.go('/login/student'),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            _isRegisterMode
                                                ? 'Назад'
                                                : 'Войти по З/К',
                                            textAlign: TextAlign.center,
                                            style: linkStyle,
                                          ),
                                        ),
                                      ),
                                      if (!_isRegisterMode) ...[
                                        const SizedBox(height: 24),
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => context.go(
                                            '/login/email',
                                            extra: const {
                                              'role': 'parent',
                                              'mode': 'login',
                                            },
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: Text(
                                              'Войти как родитель',
                                              textAlign: TextAlign.center,
                                              style: linkStyle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ],
                              ),
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
        ),
      ),
    );
  }
}
