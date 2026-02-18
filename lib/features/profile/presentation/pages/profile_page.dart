import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_header.dart';

/// Страница профиля пользователя.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        headerTitle: Text("Профиль")
      ),
      body: const Center(child: Text('Профиль студента')),
    );
  }
}
