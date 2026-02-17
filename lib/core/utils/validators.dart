/// Валидаторы полей (логин, пароль, email).
abstract final class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Введите email';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(value) ? null : 'Некорректный email';
  }

  static String? required(String? value, [String fieldName = 'Поле']) {
    if (value == null || value.trim().isEmpty) return '$fieldName обязательно';
    return null;
  }
}
