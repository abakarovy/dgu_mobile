/// Элемент новости для списка и экрана детали.
class NewsItem {
  const NewsItem({
    required this.category,
    required this.title,
    required this.excerpt,
    required this.date,
    required this.body,
    required this.imageAsset,
    this.bodyBlocks,
  });

  final String category;
  final String title;
  final String excerpt;
  final String date;
  /// Полный текст новости (используется, если [bodyBlocks] null).
  final String body;
  /// Путь к локальному изображению.
  final String imageAsset;
  /// Если задан, тело новости рисуется по блокам (обычный и курсив/цитата).
  final List<NewsBodyBlock>? bodyBlocks;
}

/// Блок текста в теле новости (обычный или курсив/цитата).
class NewsBodyBlock {
  const NewsBodyBlock(this.text, {this.italic = false});
  final String text;
  final bool italic;
}
