import 'package:flutter/material.dart';

/// Вкладка «Оценки» — контент без Scaffold/AppBar (оболочка в [AppShellPage]).
class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Список оценок'));
  }
}
