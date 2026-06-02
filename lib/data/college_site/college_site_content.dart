/// Контент с публичного сайта college.dgu.ru для раздела «Абитуриент».
class CollegeSiteContent {
  const CollegeSiteContent({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.ecosystemTitle,
    required this.ecosystemSubtitle,
    required this.features,
    required this.directionsTitle,
    required this.directionsSubtitle,
    required this.directions,
    required this.contacts,
    required this.quickLinks,
    required this.fetchedAt,
  });

  final String heroTitle;
  final String heroSubtitle;
  final String ecosystemTitle;
  final String ecosystemSubtitle;
  final List<CollegeFeatureCard> features;
  final String directionsTitle;
  final String directionsSubtitle;
  final List<CollegeDirection> directions;
  final CollegeContacts contacts;
  final List<CollegeQuickLink> quickLinks;
  final DateTime? fetchedAt;

  Map<String, dynamic> toJson() => {
        'hero_title': heroTitle,
        'hero_subtitle': heroSubtitle,
        'ecosystem_title': ecosystemTitle,
        'ecosystem_subtitle': ecosystemSubtitle,
        'features': [for (final f in features) f.toJson()],
        'directions_title': directionsTitle,
        'directions_subtitle': directionsSubtitle,
        'directions': [for (final d in directions) d.toJson()],
        'contacts': contacts.toJson(),
        'quick_links': [for (final l in quickLinks) l.toJson()],
        'fetched_at': fetchedAt?.toIso8601String(),
      };

  factory CollegeSiteContent.fromJson(Map<String, dynamic> j) {
    DateTime? fetched;
    final raw = j['fetched_at'];
    if (raw is String && raw.isNotEmpty) {
      fetched = DateTime.tryParse(raw);
    }
    return CollegeSiteContent(
      heroTitle: '${j['hero_title'] ?? ''}',
      heroSubtitle: '${j['hero_subtitle'] ?? ''}',
      ecosystemTitle: '${j['ecosystem_title'] ?? ''}',
      ecosystemSubtitle: '${j['ecosystem_subtitle'] ?? ''}',
      features: [
        for (final e in (j['features'] as List? ?? const []))
          if (e is Map) CollegeFeatureCard.fromJson(Map<String, dynamic>.from(e)),
      ],
      directionsTitle: '${j['directions_title'] ?? ''}',
      directionsSubtitle: '${j['directions_subtitle'] ?? ''}',
      directions: [
        for (final e in (j['directions'] as List? ?? const []))
          if (e is Map) CollegeDirection.fromJson(Map<String, dynamic>.from(e)),
      ],
      contacts: CollegeContacts.fromJson(
        j['contacts'] is Map ? Map<String, dynamic>.from(j['contacts'] as Map) : const {},
      ),
      quickLinks: [
        for (final e in (j['quick_links'] as List? ?? const []))
          if (e is Map) CollegeQuickLink.fromJson(Map<String, dynamic>.from(e)),
      ],
      fetchedAt: fetched,
    );
  }
}

class CollegeFeatureCard {
  const CollegeFeatureCard({required this.title, required this.body});

  final String title;
  final String body;

  Map<String, dynamic> toJson() => {'title': title, 'body': body};

  factory CollegeFeatureCard.fromJson(Map<String, dynamic> j) => CollegeFeatureCard(
        title: '${j['title'] ?? ''}',
        body: '${j['body'] ?? ''}',
      );
}

class CollegeDirection {
  const CollegeDirection({
    required this.code,
    required this.shortLabel,
    required this.title,
    required this.description,
    this.imageUrl,
    this.sitePath,
  });

  final String code;
  final String shortLabel;
  final String title;
  final String description;
  final String? imageUrl;
  final String? sitePath;

  Map<String, dynamic> toJson() => {
        'code': code,
        'short_label': shortLabel,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'site_path': sitePath,
      };

  factory CollegeDirection.fromJson(Map<String, dynamic> j) => CollegeDirection(
        code: '${j['code'] ?? ''}',
        shortLabel: '${j['short_label'] ?? ''}',
        title: '${j['title'] ?? ''}',
        description: '${j['description'] ?? ''}',
        imageUrl: j['image_url']?.toString(),
        sitePath: j['site_path']?.toString(),
      );
}

class CollegeContacts {
  const CollegeContacts({
    this.address,
    this.phone,
    this.email,
    this.vkUrl,
    this.telegramUrl,
    this.maxUrl,
  });

  final String? address;
  final String? phone;
  final String? email;
  final String? vkUrl;
  final String? telegramUrl;
  final String? maxUrl;

  Map<String, dynamic> toJson() => {
        'address': address,
        'phone': phone,
        'email': email,
        'vk_url': vkUrl,
        'telegram_url': telegramUrl,
        'max_url': maxUrl,
      };

  factory CollegeContacts.fromJson(Map<String, dynamic> j) => CollegeContacts(
        address: j['address']?.toString(),
        phone: j['phone']?.toString(),
        email: j['email']?.toString(),
        vkUrl: j['vk_url']?.toString(),
        telegramUrl: j['telegram_url']?.toString(),
        maxUrl: j['max_url']?.toString(),
      );
}

class CollegeQuickLink {
  const CollegeQuickLink({
    required this.label,
    required this.url,
    this.external = false,
    this.primary = false,
    this.inAppRoute,
  });

  final String label;
  final String url;
  final bool external;
  final bool primary;
  /// Маршрут GoRouter внутри приложения (без внешнего браузера).
  final String? inAppRoute;

  Map<String, dynamic> toJson() => {
        'label': label,
        'url': url,
        'external': external,
        'primary': primary,
        'in_app_route': inAppRoute,
      };

  factory CollegeQuickLink.fromJson(Map<String, dynamic> j) => CollegeQuickLink(
        label: '${j['label'] ?? ''}',
        url: '${j['url'] ?? ''}',
        external: j['external'] == true,
        primary: j['primary'] == true,
        inAppRoute: j['in_app_route']?.toString(),
      );
}
