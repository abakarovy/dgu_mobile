import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Позже заменить на реальную проверку авторизации (токен и т.д.).
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // Временно всегда переходим в главный экран с нижней навигацией.
    // Когда появится проверка токена: при успехе — /app/home, иначе — /auth/login.
    context.go('/app/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/splash_logo.png',
              width: 180,
              height: 180,
            ),
          ],
        ),
      ),
    );
  }
}

