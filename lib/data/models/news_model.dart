class NewsModel {
  const NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.excerpt,
    this.imageUrl,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String content;
  final String? excerpt;
  final String? imageUrl;
  final DateTime createdAt;

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      excerpt: json['excerpt'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'excerpt': excerpt,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
      };
}

