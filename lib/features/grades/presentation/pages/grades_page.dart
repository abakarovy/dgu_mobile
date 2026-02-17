import 'package:flutter/material.dart';

/// Страница просмотра оценок.
class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оценки')),
      body: const Center(child: Text('Список оценок')),
    );
  }
}
