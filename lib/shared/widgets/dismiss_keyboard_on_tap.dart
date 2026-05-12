import 'package:flutter/material.dart';

/// Скрывает клавиатуру при тапе вне интерактивных дочерних виджетов
/// (поле ввода, кнопка и т.д. по-прежнему получают жесты первыми).
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
