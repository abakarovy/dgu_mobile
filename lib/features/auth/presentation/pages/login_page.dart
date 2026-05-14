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

/// Первая буква строки и буква после пробела/дефиса — заглавные (ФИО на любом вводе).
class _CapitalizeNamePartsFormatter extends TextInputFormatter {
  const _CapitalizeNamePartsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buf = StringBuffer();
    var capNext = true;
    for (final r in text.runes) {
      final c = String.fromCharCode(r);
      if (capNext) {
        if (c == ' ' || c == '\t' || c == '-') {
          buf.write(c);
          continue;
        }
        buf.write(c.toUpperCase());
        capNext = false;
      } else {
        buf.write(c);
        if (c == ' ' || c == '\t' || c == '-') {
          capNext = true;
        }
      }
    }
    final s = buf.toString();
    if (s == text) return newValue;
    return TextEditingValue(
      text: s,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}

/// Вход по ФИО и № зачётной книжки.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _capitalizeNameParts = _CapitalizeNamePartsFormatter();

  static const Color _kBlue = Color(0xFF2E63D5);
  static const Color _kBorderMuted = Color(0x38000000);
  static const Color _kBorderFilled = Color(0xFF000000);

  static const double _formHorizontalInset = 30;
  static const double _fieldH = 60;
  static const double _radius = 46;

  /// Визуальная высота одной строки (Inter 16 / height 1.0) для вертикальных полей в `_fieldH`.
  static const double _inputLineHeight = 22;

  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _patronymic = TextEditingController();
  final _book = TextEditingController();

  final _fnLast = FocusNode();
  final _fnFirst = FocusNode();
  final _fnPat = FocusNode();
  final _fnBook = FocusNode();

  bool _submitting = false;
  bool _showError = false;
  String _errorMsg = '';

  void _onUiChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    for (final n in [_fnLast, _fnFirst, _fnPat, _fnBook]) {
      n.addListener(_onUiChanged);
    }
    for (final c in [_lastName, _firstName, _patronymic, _book]) {
      c.addListener(_onUiChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [_lastName, _firstName, _patronymic, _book]) {
      c.dispose();
    }
    for (final n in [_fnLast, _fnFirst, _fnPat, _fnBook]) {
      n.dispose();
    }
    super.dispose();
  }

  void _logSupportStubForVerify1c({required String errorMessage}) {
    final lastName = _lastName.text.trim();
    final firstName = _firstName.text.trim();
    final patronymic = _patronymic.text.trim();
    final book = _book.text.trim();
    final fullName = [lastName, firstName, patronymic].join(' ');
    debugPrint(
      '[SupportStub] verify-1c | error: $errorMessage | '
      'fullName: $fullName | student_book_number: $book | '
      'поля: фамилия="$lastName", имя="$firstName", отчество="$patronymic", зачётка="$book"',
    );
  }

  Future<void> _showVerify1cErrorDialog({required String message}) async {
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
            'Не удалось проверить данные',
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
            TextButton(
              onPressed: () {
                _logSupportStubForVerify1c(errorMessage: message);
                Navigator.of(ctx).pop();
              },
              child: Text(
                'Отправить в поддержку',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.0,
                  color: _kBlue,
                ),
              ),
            ),
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

  Color _borderColor(FocusNode fn, TextEditingController c) {
    if (fn.hasFocus) return _kBlue;
    if (c.text.trim().isNotEmpty) return _kBorderFilled;
    return _kBorderMuted;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final empty =
        _lastName.text.trim().isEmpty ||
        _firstName.text.trim().isEmpty ||
        _patronymic.text.trim().isEmpty ||
        _book.text.trim().isEmpty;
    if (empty) {
      setState(() {
        _showError = true;
        _errorMsg = 'Заполните все поля';
      });
      return;
    }
    setState(() {
      _showError = false;
      _submitting = true;
    });
    final fullName = [
      _lastName.text.trim(),
      _firstName.text.trim(),
      _patronymic.text.trim(),
    ].join(' ');
    final book = _book.text.trim();
    try {
      final registrationToken = await AppContainer.authRepository
          .verifyStudentIn1c(fullName: fullName, studentBookNumber: book);
      if (!mounted) return;
      context.go(
        '/login/email',
        extra: {
          'mode': 'register',
          'fullName': fullName,
          'book': book,
          'registrationToken': registrationToken,
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      await _showVerify1cErrorDialog(message: e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  ButtonStyle _noOverlay(ButtonStyle base) {
    return base.copyWith(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  Widget _outlineField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    FocusNode? nextFocus,
    VoidCallback? onLastSubmitted,
    TextInputType keyboardType = TextInputType.name,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isLast = nextFocus == null;
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
          border: Border.all(
            color: _borderColor(focusNode, controller),
            width: 1,
          ),
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
                  // Горизонтально слева; вертикально по центру пилюли — через contentPadding.
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.ltr,
                  textInputAction: isLast
                      ? TextInputAction.done
                      : TextInputAction.next,
                  inputFormatters: inputFormatters,
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
            ],
          ),
        ),
      ),
    );
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
                                  if (_showError) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Text(
                                        _errorMsg,
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
                                  _outlineField(
                                    controller: _lastName,
                                    focusNode: _fnLast,
                                    hint: 'Фамилия',
                                    nextFocus: _fnFirst,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    inputFormatters: const [
                                      _capitalizeNameParts,
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _outlineField(
                                    controller: _firstName,
                                    focusNode: _fnFirst,
                                    hint: 'Имя',
                                    nextFocus: _fnPat,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    inputFormatters: const [
                                      _capitalizeNameParts,
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _outlineField(
                                    controller: _patronymic,
                                    focusNode: _fnPat,
                                    hint: 'Отчество',
                                    nextFocus: _fnBook,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    inputFormatters: const [
                                      _capitalizeNameParts,
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _outlineField(
                                    controller: _book,
                                    focusNode: _fnBook,
                                    hint: 'Номер зачетной книжки',
                                    onLastSubmitted: _submit,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(5),
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
                                            borderRadius: BorderRadius.circular(
                                              _radius,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          elevation: 0,
                                        ),
                                      ),
                                      child: _submitting
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text('Войти', style: btnLabel),
                                    ),
                                  ),
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
                                        'Войти по E-mail',
                                        textAlign: TextAlign.center,
                                        style: linkStyle,
                                      ),
                                    ),
                                  ),
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
