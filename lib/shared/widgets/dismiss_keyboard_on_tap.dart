import 'package:flutter/material.dart';

/// Скрывает клавиатуру при тапе вне интерактивных дочерних виджетов
/// (поле ввода, кнопка и т.д. по-прежнему получают жесты первыми).
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // translucent: ловили жест параллельно с Focusable — IME «Далее» иногда давал моргание клавиатуры.
    // deferToChild: только туда, где дети не обработали тап (фон формы между полями и т.д.).
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.deferToChild,
      child: child,
    );
  }
}
