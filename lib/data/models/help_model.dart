class HelpModel {
  const HelpModel({
    this.hotlinePhone,
    this.email,
    this.websiteUrl,
    this.faq,
  });

  final String? hotlinePhone;
  final String? email;
  final String? websiteUrl;
  final List<HelpFaqItem>? faq;

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

    return HelpModel(
      hotlinePhone: s(json['hotline_phone'] ?? json['hotline'] ?? json['phone'] ?? json['tel']),
      email: s(json['email'] ?? json['support_email']),
      websiteUrl: s(json['website'] ?? json['website_url'] ?? json['site']),
      faq: faq,
    );
  }
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

