import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';

/// Экран входа: иконка в контейнере, заголовок, подзаголовок, форма (Фамилия, Имя, Отчество, Номер з/к), кнопка «Войти».
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _studentIdController = TextEditingController();

  final _lastNameFocusNode = FocusNode();
  final _firstNameFocusNode = FocusNode();
  final _patronymicFocusNode = FocusNode();
  final _studentIdFocusNode = FocusNode();

  final Set<String> _errorFields = {};
  bool _showWrongCredentialsError = false;
  String _credentialsErrorMessage = 'Неверные Ф.И.О. или № зач. книжки!';
  bool _submitting = false;

  bool _hasText(TextEditingController c) => c.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _lastNameFocusNode.addListener(() {
      if (_lastNameFocusNode.hasFocus) {
        setState(() {
          _errorFields.remove('lastName');
          _showWrongCredentialsError = false;
        });
      }
    });
    _firstNameFocusNode.addListener(() {
      if (_firstNameFocusNode.hasFocus) {
        setState(() {
          _errorFields.remove('firstName');
          _showWrongCredentialsError = false;
        });
      }
    });
    _patronymicFocusNode.addListener(() {
      if (_patronymicFocusNode.hasFocus) {
        setState(() {
          _errorFields.remove('patronymic');
          _showWrongCredentialsError = false;
        });
      }
    });
    _studentIdFocusNode.addListener(() {
      if (_studentIdFocusNode.hasFocus) {
        setState(() {
          _errorFields.remove('studentId');
          _showWrongCredentialsError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    _studentIdController.dispose();
    _lastNameFocusNode.dispose();
    _firstNameFocusNode.dispose();
    _patronymicFocusNode.dispose();
    _studentIdFocusNode.dispose();
    super.dispose();
  }

  String _fullName() {
    final parts = [
      _lastNameController.text.trim(),
      _firstNameController.text.trim(),
      _patronymicController.text.trim(),
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(' ');
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final errors = <String>{};
    if (_lastNameController.text.trim().isEmpty) errors.add('lastName');
    if (_firstNameController.text.trim().isEmpty) errors.add('firstName');
    if (_patronymicController.text.trim().isEmpty) errors.add('patronymic');
    if (_studentIdController.text.trim().isEmpty) errors.add('studentId');
    setState(() {
      _errorFields
        ..clear()
        ..addAll(errors);
      _showWrongCredentialsError = false;
    });
    if (errors.isNotEmpty) return;

    final fullName = _fullName();
    final bookNumber = _studentIdController.text.trim();
    try {
      setState(() => _submitting = true);
      // Проверяем студента в 1С. Дальше — регистрация/вход по email.
      final registrationToken = await AppContainer.authRepository
          .verifyStudentIn1c(fullName: fullName, studentBookNumber: bookNumber);
      if (!mounted) return;
      context.go(
        '/login/email',
        extra: {
          'mode': 'register',
          'fullName': fullName,
          'book': bookNumber,
          'registrationToken': registrationToken,
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _showWrongCredentialsError = true;
        _credentialsErrorMessage = e.message;
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
    final sfW = size.width / figmaW;
    final blue = const Color.fromRGBO(46, 99, 213, 1);
    final fieldRadius = 89.16 * sf;
    final fieldBorderW = (4.46 * sf).clamp(2.0, 6.0);
    // Поля должны быть той же высоты, что и кнопки.
    final fieldHeight = (120.0 * sf).clamp(56.0, 140.0);
    final fieldLeftPad = 75.0 * sf;
    final sidePad = 40.0 * sf;
    final gap = (10.0 * sf).clamp(6.0, 14.0);

    // Кнопки: тот же стиль, что «Я студент / Я родитель».
    final btnRadius = 117.96 * sf;
    final btnBorder = (7.07 * sf).clamp(3.0, 10.0);
    final btnTextStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 45.47 * sf,
      height: 1.0,
    );
    // Кнопки ниже и компактнее, чем поля (но в стиле экрана выбора роли).
    final btnHeight = fieldHeight;

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

    final noTapFxTheme = Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );

    // Островок / Dynamic Island / статус-бар: заголовки — ниже «выреза», фото — чуть выше по доле экрана.
    final safeTop = MediaQuery.paddingOf(context).top;
    const photoFlex = 2;
    const formFlex = 3;

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
                      left: 60 * sf,
                      top: safeTop + 56 * sf,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Студент',
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
                flex: formFlex,
                child: SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final innerMaxW = math.max(
                        0.0,
                        constraints.maxWidth - 2 * sidePad,
                      );
                      // Ширина колонки только от ширины экрана (900×sfW), не от min(w,h) — иначе
                      // на низком окне поля и кнопки становятся непропорционально узкими.
                      final formColumnW = math.min(900.0 * sfW, innerMaxW);
                      final content = SizedBox(
                        width: formColumnW,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_showWrongCredentialsError) ...[
                              Text(
                                _credentialsErrorMessage,
                                textAlign: TextAlign.center,
                                style: AppTextStyle.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  height: 1.2,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: gap),
                            ],
                            _buildForm(
                              fieldHeight: fieldHeight,
                              fieldRadius: fieldRadius,
                              fieldBorderW: fieldBorderW,
                              fieldLeftPad: fieldLeftPad,
                              blue: blue,
                              hintStyle: hintStyle,
                              valueStyle: valueStyle,
                              gap: gap,
                            ),
                            SizedBox(height: gap),

                            SizedBox(
                              height: btnHeight,
                              child: FilledButton(
                                onPressed: _submitting ? null : _submit,
                                style: noOverlay(
                                  FilledButton.styleFrom(
                                    backgroundColor: blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        btnRadius,
                                      ),
                                    ),
                                    fixedSize: Size.fromHeight(btnHeight),
                                    minimumSize: Size(
                                      double.infinity,
                                      btnHeight,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    textStyle: btnTextStyle,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _submitting ? 'Проверяем…' : 'Войти',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: gap),

                            SizedBox(
                              height: btnHeight,
                              child: OutlinedButton(
                                onPressed: () => context.go(
                                  '/login/email',
                                  extra: const {
                                    'role': 'student',
                                    'mode': 'login',
                                  },
                                ),
                                style: noOverlay(
                                  OutlinedButton.styleFrom(
                                    foregroundColor: blue,
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(
                                      color: blue,
                                      width: btnBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        btnRadius,
                                      ),
                                    ),
                                    fixedSize: Size.fromHeight(btnHeight),
                                    minimumSize: Size(
                                      double.infinity,
                                      btnHeight,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    textStyle: btnTextStyle,
                                  ),
                                ),
                                child: const Center(
                                  child: Text('Войти по E-mail'),
                                ),
                              ),
                            ),
                            SizedBox(height: gap),

                            SizedBox(
                              height: btnHeight,
                              child: FilledButton(
                                onPressed: () => context.go(
                                  '/login/email',
                                  extra: const {
                                    'role': 'parent',
                                    'mode': 'login',
                                  },
                                ),
                                style: noOverlay(
                                  FilledButton.styleFrom(
                                    backgroundColor: blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        btnRadius,
                                      ),
                                    ),
                                    fixedSize: Size.fromHeight(btnHeight),
                                    minimumSize: Size(
                                      double.infinity,
                                      btnHeight,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    textStyle: btnTextStyle,
                                  ),
                                ),
                                child: const Center(
                                  child: Text('Войти как родитель'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          sidePad,
                          18 * sf,
                          sidePad,
                          18 * sf,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
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

  Widget _buildForm({
    required double fieldHeight,
    required double fieldRadius,
    required double fieldBorderW,
    required double fieldLeftPad,
    required Color blue,
    required TextStyle hintStyle,
    required TextStyle valueStyle,
    required double gap,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(
            key: 'lastName',
            hint: 'Фамилия',
            controller: _lastNameController,
            focusNode: _lastNameFocusNode,
            nextFocus: _firstNameFocusNode,
            fieldHeight: fieldHeight,
            fieldRadius: fieldRadius,
            fieldBorderW: fieldBorderW,
            fieldLeftPad: fieldLeftPad,
            blue: blue,
            hintStyle: hintStyle,
            valueStyle: valueStyle,
          ),
          SizedBox(height: gap),
          _buildField(
            key: 'firstName',
            hint: 'Имя',
            controller: _firstNameController,
            focusNode: _firstNameFocusNode,
            nextFocus: _patronymicFocusNode,
            fieldHeight: fieldHeight,
            fieldRadius: fieldRadius,
            fieldBorderW: fieldBorderW,
            fieldLeftPad: fieldLeftPad,
            blue: blue,
            hintStyle: hintStyle,
            valueStyle: valueStyle,
          ),
          SizedBox(height: gap),
          _buildField(
            key: 'patronymic',
            hint: 'Отчество',
            controller: _patronymicController,
            focusNode: _patronymicFocusNode,
            nextFocus: _studentIdFocusNode,
            fieldHeight: fieldHeight,
            fieldRadius: fieldRadius,
            fieldBorderW: fieldBorderW,
            fieldLeftPad: fieldLeftPad,
            blue: blue,
            hintStyle: hintStyle,
            valueStyle: valueStyle,
          ),
          SizedBox(height: gap),
          _buildField(
            key: 'studentId',
            hint: 'Номер з/к',
            controller: _studentIdController,
            focusNode: _studentIdFocusNode,
            nextFocus: null,
            onLastFieldSubmitted: _submit,
            keyboardType: TextInputType.number,
            maxLength: 5,
            fieldHeight: fieldHeight,
            fieldRadius: fieldRadius,
            fieldBorderW: fieldBorderW,
            fieldLeftPad: fieldLeftPad,
            blue: blue,
            hintStyle: hintStyle,
            valueStyle: valueStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String key,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    VoidCallback? onLastFieldSubmitted,
    TextInputType keyboardType = TextInputType.name,
    bool obscureText = false,
    int? maxLength,
    required double fieldHeight,
    required double fieldRadius,
    required double fieldBorderW,
    required double fieldLeftPad,
    required Color blue,
    required TextStyle hintStyle,
    required TextStyle valueStyle,
    VoidCallback? onPasswordVisibilityToggle,
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

    final fs = valueStyle.fontSize ?? 16;
    final lineH = fs * (valueStyle.height ?? 1.0);
    final vPad = ((fieldHeight - 2 * fieldBorderW - lineH) / 2).clamp(0.0, fieldHeight);
    final rightPad = onPasswordVisibilityToggle != null ? 12.0 : 24.0;

    return SizedBox(
      height: fieldHeight,
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction:
            nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            nextFocus.requestFocus();
          } else {
            onLastFieldSubmitted?.call();
          }
        },
        strutStyle: StrutStyle(
          fontSize: fs,
          height: valueStyle.height,
          fontFamily: valueStyle.fontFamily,
          fontWeight: valueStyle.fontWeight,
          forceStrutHeight: true,
        ),
        inputFormatters: [
          if (keyboardType == TextInputType.number)
            FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: hintStyle,
          filled: false,
          isDense: false,
          constraints: BoxConstraints(
            minHeight: fieldHeight,
            maxHeight: fieldHeight,
          ),
          border: enabledBorder,
          enabledBorder: enabledBorder,
          focusedBorder: focusedBorder,
          errorBorder: enabledBorder.copyWith(
            borderSide: BorderSide(color: Colors.red, width: fieldBorderW),
          ),
          focusedErrorBorder: focusedBorder.copyWith(
            borderSide: BorderSide(color: Colors.red, width: fieldBorderW),
          ),
          suffixIcon: onPasswordVisibilityToggle == null
              ? null
              : IconButton(
                  onPressed: onPasswordVisibilityToggle,
                  tooltip:
                      obscureText ? 'Показать пароль' : 'Скрыть пароль',
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.only(right: fieldLeftPad),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: fs,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
          contentPadding: EdgeInsets.only(
            left: fieldLeftPad,
            right: rightPad,
            top: vPad,
            bottom: vPad,
          ),
          errorText: null,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          counterText: '',
        ),
        style: valueStyle,
        onChanged: (_) {
          // Чтобы обновлять цвет обводки (пусто/есть текст) и стиль значения.
          if (mounted) setState(() {});
        },
      ),
    );
  }

  // _buildSwitchButton больше не используется: все кнопки в стиле «Я студент / Я родитель».
}
