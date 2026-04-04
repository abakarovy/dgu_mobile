import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';

class LoginRolePage extends StatelessWidget {
  const LoginRolePage({super.key});

  static const _figmaW = 1080.0;
  static const _figmaH = 1920.0;

  static double _sf(Size s) {
    final sw = s.width / _figmaW;
    final sh = s.height / _figmaH;
    return math.min(sw, sh);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sf = _sf(size);
    final blue = const Color.fromRGBO(46, 99, 213, 1);

    // Разбивка: верх с фото чуть выше (2:3 ≈ 40% экрана), ниже — форма; учёт островка в позиции текста.
    const topFlex = 2;
    const bottomFlex = 3;
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

    final btnRadius = 117.96 * sf;
    final btnBorder = (7.07 * sf).clamp(3.0, 10.0);
    final btnTextStyle = AppTextStyle.inter(
      fontWeight: FontWeight.w700,
      fontSize: 45.47 * sf,
      height: (70.73 / 45.47),
    );
    final btnHeight = (145.0 * sf).clamp(64.0, 190.0);
    final btnGap = (10.0 * sf).clamp(6.0, 14.0);

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

    return Theme(
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
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 24 * sf),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 900 * sf),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 60 * sf),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: btnHeight,
                              child: OutlinedButton(
                                onPressed: () => context.go('/login/student'),
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
                                child: const Text('Я студент'),
                              ),
                            ),
                            SizedBox(height: btnGap),
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
                                child: const Text('Я родитель'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
