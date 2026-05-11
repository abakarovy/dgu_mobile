import '../../../data/models/event_model.dart';

class EventItem {
  const EventItem({
    this.imageAsset,
    this.imageUrl,
    required this.category,
    required this.title,
    required this.description,
    required this.dateRange,
    required this.location,
  });

  final String? imageAsset;
  final String? imageUrl;
  final String category;
  final String title;
  final String description;
  final String dateRange;
  final String location;

  factory EventItem.fromEventModel(EventModel e) {
    return EventItem(
      imageUrl: e.imageUrl,
      category: (e.category?.isNotEmpty ?? false) ? e.category! : 'Мероприятие',
      title: e.title,
      description: e.description,
      dateRange: e.dateRangeLabel.isNotEmpty ? e.dateRangeLabel : '—',
      location: (e.location?.isNotEmpty ?? false) ? e.location! : '—',
    );
  }
}

