import 'package:flutter/material.dart';

/// Страница профиля пользователя.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: const Center(child: Text('Профиль студента')),
    );
  }
}
