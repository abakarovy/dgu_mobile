import 'package:dgu_mobile/core/constants/api_constants.dart';

class NewsModel {
  const NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.excerpt,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.isPublished = true,
  });

  final int id;
  final String title;
  final String content;
  final String? excerpt;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  /// Скрывать в ленте и по умолчанию не показывать, если `false` (см. MOBILE_NEWS_PUSH).
  final bool isPublished;

  static bool _parsePublished(dynamic v) {
    if (v == null) return true;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = '$v'.toLowerCase().trim();
    if (s == 'false' || s == '0' || s == 'no') return false;
    return true;
  }

  static String? _str(dynamic v) =>
      v == null ? null : (v is String ? v : '$v').trim();

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : idRaw is num
            ? idRaw.toInt()
            : int.tryParse('$idRaw') ?? 0;

    final created =
        DateTime.tryParse(_str(json['created_at']) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

    return NewsModel(
      id: id,
      title: '${json['title'] ?? ''}',
      content: '${json['content'] ?? ''}',
      excerpt: _str(json['excerpt']),
      imageUrl: _str(json['image_url']),
      createdAt: created,
      updatedAt: DateTime.tryParse(_str(json['updated_at']) ?? ''),
      isPublished: _parsePublished(json['is_published']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'excerpt': excerpt,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_published': isPublished,
      };

  /// Превью для карточки: без HTML, до ~160 символов из `excerpt` или `content`.
  String get cardExcerptPlain {
    final ex = excerpt;
    if (ex != null && ex.isNotEmpty) {
      final p = stripHtmlToPlain(ex, maxLen: 320);
      if (p.isNotEmpty) return p;
    }
    return stripHtmlToPlain(content, maxLen: 160);
  }

  static String stripHtmlToPlain(String? html, {int maxLen = 160}) {
    if (html == null || html.isEmpty) return '';
    var s = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (maxLen > 0 && s.runes.length > maxLen) {
      s = '${String.fromCharCodes(s.runes.take(maxLen)).trim()}…';
    }
    return s;
  }

  /// Локальный ассет из `pubspec` (моки: `assets/images/...`).
  static String? bundleAssetPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final t = path.trim();
    if (t.startsWith('assets/')) return t;
    return null;
  }

  /// Полный URL картинки: бэкенд часто отдаёт `/uploads/...` относительно хоста (не `/api`).
  /// Пути `assets/...` не превращаются в URL — используйте [bundleAssetPath] и [Image.asset].
  static String? resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final t = path.trim();
    if (t.startsWith('assets/')) return null;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final base = Uri.parse(ApiConstants.baseUrl);
    final origin = base.origin;
    if (t.startsWith('/')) return '$origin$t';
    return '$origin/$t';
  }
}

