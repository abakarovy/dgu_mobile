import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';

/// Выбор роли: студент или родитель.
class LoginRolePage extends StatelessWidget {
  const LoginRolePage({super.key});

  static const _figmaW = 1080.0;
  static const _figmaH = 1920.0;
  static const Color _kBlue = Color(0xFF2E63D5);

  /// Горизонтальные поля белого блока под кнопками («Я студент» / «Я родитель»).
  static const double _buttonHorizontalInset = 30;

  static double _sf(Size s) {
    final sw = s.width / _figmaW;
    final sh = s.height / _figmaH;
    return math.min(sw, sh);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sf = _sf(size);

    const topFlex = 2;
    const bottomFlex = 4;
    final safeTop = MediaQuery.paddingOf(context).top;

    final titleStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 111.73 * sf,
      height: 1.0,
      color: Colors.white,
    );
    final collegeStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 32.96 * sf * 1.25,
      height: 1.0,
      letterSpacing: -0.82 * sf * 1.25,
      color: Colors.white,
    );

    final noTapFxTheme = Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );

    final btnLabelStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 22,
      height: 1.0,
    );

    ButtonStyle noOverlay(ButtonStyle base) {
      return base.copyWith(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
          body: Column(
            children: [
              Expanded(
                flex: topFlex,
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
                          Text('Начни сейчас', style: titleStyle),
                          SizedBox(height: 20 * sf),
                          Text('КОЛЛЕДЖ ДГУ', style: collegeStyle),
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
                flex: bottomFlex,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _buttonHorizontalInset,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 60,
                          child: OutlinedButton(
                            onPressed: () => context.go('/login/student'),
                            style: noOverlay(
                              OutlinedButton.styleFrom(
                                foregroundColor: _kBlue,
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(color: _kBlue, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(46),
                                ),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            child: Text(
                              'Я студент',
                              textAlign: TextAlign.center,
                              style: btnLabelStyle.copyWith(color: _kBlue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 60,
                          child: FilledButton(
                            onPressed: () => context.go(
                              '/login/email',
                              extra: const {'role': 'parent', 'mode': 'login'},
                            ),
                            style: noOverlay(
                              FilledButton.styleFrom(
                                backgroundColor: _kBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(46),
                                ),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                elevation: 0,
                              ),
                            ),
                            child: Text(
                              'Я родитель',
                              textAlign: TextAlign.center,
                              style: btnLabelStyle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
