import 'package:flutter/material.dart';

/// Пустой белый экран на время проверки сессии (без логотипа и индикатора).
class AppSplashView extends StatelessWidget {
  const AppSplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(),
    );
  }
}
