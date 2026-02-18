import 'package:flutter/material.dart';

/// Заголовок главной страницы: иконка колледжа + текст «КОЛЛЕДЖ ДГУ».
class HomeHeaderTitle extends StatelessWidget {
  const HomeHeaderTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_icon.png',
          height: 32,
          width: 32,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Text(
          'КОЛЛЕДЖ ДГУ',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
