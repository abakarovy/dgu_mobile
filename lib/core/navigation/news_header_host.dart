import 'package:flutter/foundation.dart';

/// Глобальный хост для заголовка AppBar на вкладке «Новости».
///
/// Нужно, чтобы при переключении «Новости/Мероприятия» внутри одной вкладки
/// можно было менять текст в AppBar, не трогая роутер и shell.
abstract final class NewsHeaderHost {
  static final ValueNotifier<String> title = ValueNotifier<String>('Новости');

  static void setTitle(String value) {
    if (title.value == value) return;
    title.value = value;
  }
}

