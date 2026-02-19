import 'package:flutter/material.dart';

/// Вкладка «Профиль» — контент без Scaffold/AppBar (оболочка в [AppShellPage]).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Профиль студента'));
  }
}
