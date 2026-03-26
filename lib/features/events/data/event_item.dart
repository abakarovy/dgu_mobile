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
}

