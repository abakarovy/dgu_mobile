/// ФИО для UI: не «ВСЕ ЗАГЛАВНЫЕ», а первая буква слова — заглавная.
String formatPersonNameDisplay(String raw) {
  final s = raw.trim();
  if (s.isEmpty || s == '-') return s;
  return s
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) {
        if (w.length == 1) return w.toUpperCase();
        return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
      })
      .join(' ');
}
