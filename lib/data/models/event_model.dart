import 'package:intl/intl.dart';

class EventModel {
  const EventModel({
    this.id,
    required this.title,
    required this.description,
    this.category,
    this.location,
    this.imageUrl,
    this.startAt,
    this.endAt,
  });

  final int? id;
  final String title;
  final String description;
  final String? category;
  final String? location;
  final String? imageUrl;
  final DateTime? startAt;
  final DateTime? endAt;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => v is String ? v : (v == null ? null : '$v');
    DateTime? dt(dynamic v) => DateTime.tryParse(str(v) ?? '');

    return EventModel(
      id: (json['id'] is int) ? (json['id'] as int) : int.tryParse(str(json['id']) ?? ''),
      title: (str(json['title']) ?? str(json['name']) ?? 'Мероприятие').trim(),
      description: (str(json['description']) ?? str(json['content']) ?? '').trim(),
      category: (str(json['category']) ?? str(json['type']) ?? str(json['kind']))?.trim(),
      location: (str(json['location']) ?? str(json['place']) ?? str(json['address']))?.trim(),
      imageUrl: (str(json['image_url']) ?? str(json['image']) ?? str(json['banner_url']))?.trim(),
      startAt: dt(json['start_at'] ?? json['start_date'] ?? json['date_start']),
      endAt: dt(json['end_at'] ?? json['end_date'] ?? json['date_end']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'image_url': imageUrl,
        'start_at': startAt?.toIso8601String(),
        'end_at': endAt?.toIso8601String(),
      };

  String get dateRangeLabel {
    final s = startAt;
    final e = endAt;
    if (s == null && e == null) return '';
    final f = DateFormat('dd.MM.yyyy');
    if (s != null && e != null) return '${f.format(s)} — ${f.format(e)}';
    if (s != null) return f.format(s);
    return f.format(e!);
  }
}

