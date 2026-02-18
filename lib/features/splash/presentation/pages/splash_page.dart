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
    // TODO: заменить на реальную проверку авторизации.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // Временно всегда переходим в главный экран с нижней навигацией.
    // Когда появится проверка токена: при успехе — /app/home, иначе — /auth/login.
    context.go('/app/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
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

