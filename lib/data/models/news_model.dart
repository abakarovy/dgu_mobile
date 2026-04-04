import 'package:dgu_mobile/core/constants/api_constants.dart';

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
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : idRaw is num
            ? idRaw.toInt()
            : int.tryParse('$idRaw') ?? 0;

    return NewsModel(
      id: id,
      title: '${json['title'] ?? ''}',
      content: '${json['content'] ?? ''}',
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

  /// Полный URL картинки: бэкенд часто отдаёт `/uploads/...` относительно хоста (не `/api`).
  static String? resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final t = path.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base = Uri.parse(ApiConstants.baseUrl);
    final origin = base.origin;
    if (t.startsWith('/')) return '$origin$t';
    return '$origin/$t';
  }
}

