import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_header.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        headerTitle: Text("Оценки")
      ),
      body: const Center(child: Text('Список оценок')),
    );
  }
}
