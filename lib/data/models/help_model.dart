class HelpDisclosureBasic {
  const HelpDisclosureBasic({
    this.orgCreatedDate,
    this.founders,
    this.locationBranches,
    this.workSchedule,
    this.phones,
    this.email,
  });

  final String? orgCreatedDate;
  final String? founders;
  final String? locationBranches;
  final String? workSchedule;
  final String? phones;
  final String? email;

  factory HelpDisclosureBasic.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) {
      final out = (v is String) ? v.trim() : (v == null ? '' : '$v').trim();
      return out.isEmpty ? null : out;
    }

    return HelpDisclosureBasic(
      orgCreatedDate: s(json['org_created_date']),
      founders: s(json['founders']),
      locationBranches: s(json['location_branches']),
      workSchedule: s(json['work_schedule']),
      phones: s(json['phones']),
      email: s(json['email']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (orgCreatedDate != null) 'org_created_date': orgCreatedDate,
        if (founders != null) 'founders': founders,
        if (locationBranches != null) 'location_branches': locationBranches,
        if (workSchedule != null) 'work_schedule': workSchedule,
        if (phones != null) 'phones': phones,
        if (email != null) 'email': email,
      };

  bool get hasAnyContent =>
      (orgCreatedDate ?? '').isNotEmpty ||
      (founders ?? '').isNotEmpty ||
      (locationBranches ?? '').isNotEmpty ||
      (workSchedule ?? '').isNotEmpty ||
      (phones ?? '').isNotEmpty ||
      (email ?? '').isNotEmpty;
}

class HelpManagementContact {
  const HelpManagementContact({
    this.unitName,
    this.headFullName,
    this.address,
    this.siteUrl,
    this.email,
  });

  final String? unitName;
  final String? headFullName;
  final String? address;
  final String? siteUrl;
  final String? email;

  factory HelpManagementContact.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) {
      final out = (v is String) ? v.trim() : (v == null ? '' : '$v').trim();
      return out.isEmpty ? null : out;
    }

    return HelpManagementContact(
      unitName: s(json['unit_name']),
      headFullName: s(json['head_full_name']),
      address: s(json['address']),
      siteUrl: s(json['site_url']),
      email: s(json['email']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (unitName != null) 'unit_name': unitName,
        if (headFullName != null) 'head_full_name': headFullName,
        if (address != null) 'address': address,
        if (siteUrl != null) 'site_url': siteUrl,
        if (email != null) 'email': email,
      };
}

class HelpModel {
  const HelpModel({
    this.hotlinePhone,
    this.email,
    this.websiteUrl,
    this.faq,
    this.disclosureBasic,
    this.managementContacts,
  });

  final String? hotlinePhone;
  final String? email;
  final String? websiteUrl;
  final List<HelpFaqItem>? faq;
  final HelpDisclosureBasic? disclosureBasic;
  final List<HelpManagementContact>? managementContacts;

  factory HelpModel.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) {
      final out = (v is String) ? v.trim() : (v == null ? '' : '$v').trim();
      return out.isEmpty ? null : out;
    }

    final rawFaq = json['faq'] ?? json['items'] ?? json['questions'];
    final faq = (rawFaq is List)
        ? rawFaq
            .whereType<Map>()
            .map((m) => HelpFaqItem.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : null;

    HelpDisclosureBasic? disc;
    final rawDisc = json['disclosure_basic'];
    if (rawDisc is Map) {
      disc = HelpDisclosureBasic.fromJson(Map<String, dynamic>.from(rawDisc));
      if (!disc.hasAnyContent) disc = null;
    }

    List<HelpManagementContact>? mgmt;
    final rawMgmt = json['management_contacts'];
    if (rawMgmt is List) {
      mgmt = rawMgmt
          .whereType<Map>()
          .map((m) => HelpManagementContact.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return HelpModel(
      hotlinePhone: s(json['hotline_phone'] ?? json['hotline'] ?? json['phone'] ?? json['tel']),
      email: s(json['email'] ?? json['support_email']),
      websiteUrl: s(json['website'] ?? json['website_url'] ?? json['site']),
      faq: faq,
      disclosureBasic: disc,
      managementContacts: mgmt,
    );
  }

  /// Сериализация для [JsonCache] (поддержка / prefetch / экран поддержки).
  Map<String, dynamic> toCacheJson() => {
        'hotline_phone': hotlinePhone,
        'hotline': hotlinePhone,
        'email': email,
        'website_url': websiteUrl,
        'faq': [
          for (final f in (faq ?? const []))
            {'title': f.title, 'answer': f.answer},
        ],
        if (disclosureBasic != null) 'disclosure_basic': disclosureBasic!.toJson(),
        'management_contacts': [
          for (final m in (managementContacts ?? const [])) m.toJson(),
        ],
      };
}

class HelpFaqItem {
  const HelpFaqItem({required this.title, this.answer});

  final String title;
  final String? answer;

  factory HelpFaqItem.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v is String) ? v.trim() : (v == null ? '' : '$v').trim();
    final title = s(json['title'] ?? json['question'] ?? json['q']);
    final answer = s(json['answer'] ?? json['a'] ?? json['text']);
    return HelpFaqItem(
      title: title.isEmpty ? 'Вопрос' : title,
      answer: answer.isEmpty ? null : answer,
    );
  }
}
