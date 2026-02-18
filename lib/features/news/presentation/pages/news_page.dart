import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_header.dart';

/// Вкладка «Новости» в нижней навигации.
class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        headerTitle: Text("Новости")
      ),
      body: const Center(
        child: Text('Новости колледжа'),
      ),
    );
  }
}
