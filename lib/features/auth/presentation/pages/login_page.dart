import 'package:flutter/material.dart';

/// Страница входа в приложение.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: const Center(child: Text('Экран входа')),
    );
  }
}
