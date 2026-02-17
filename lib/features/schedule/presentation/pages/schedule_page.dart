import 'package:flutter/material.dart';

/// Страница расписания занятий.
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Расписание')),
      body: const Center(child: Text('Расписание занятий')),
    );
  }
}
