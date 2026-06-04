import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Splash в Flutter: логотип по центру, индикатор внизу (native — только белый фон).
class AppSplashView extends StatelessWidget {
  const AppSplashView({super.key});

  static const String _logoAsset = 'assets/images/logo_app_2.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Image.asset(
                _logoAsset,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primaryBlue,
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
