/// Внешние Мои курсы (LMS): запасной список, если `/api/lms` пуст или недоступен.
class LmsResourceLinks {
  LmsResourceLinks._();

  static const List<({String title, String url})> fallback = [
    (title: 'Юрайт', url: 'https://urait.ru/'),
    (title: 'ПРОФ СПО', url: 'https://profspo.ru/'),
    (title: 'Академия Москва', url: 'https://academia-moscow.ru/'),
  ];

  static List<({String title, String url})> fromApi(List<Map<String, dynamic>> raw) {
    final out = <({String title, String url})>[];
    for (final m in raw) {
      final title = '${m['title'] ?? m['name'] ?? ''}'.trim();
      final url = '${m['url'] ?? ''}'.trim();
      if (title.isEmpty || url.isEmpty) continue;
      out.add((title: title, url: url));
    }
    return out;
  }
}
