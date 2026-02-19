import 'package:flutter/material.dart';

/// Вкладка «Новости» — контент без Scaffold/AppBar (оболочка в [AppShellPage]).
class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Новости колледжа'));
  }
}
