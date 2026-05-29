import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import '../../core/constants/api_constants.dart';
import 'college_site_content.dart';
import 'college_site_fallback.dart';

/// Парсинг SSR-HTML главной страницы college.dgu.ru.
abstract final class CollegeSiteParser {
  static CollegeSiteContent parseHomeHtml(String html, {DateTime? fetchedAt}) {
    final doc = parse(html);
    final origin = ApiConstants.collegeSiteOrigin;

    var heroTitle = 'Колледж ДГУ';
    var heroSubtitle = CollegeSiteFallback.defaultContent.heroSubtitle;

    final h1 = doc.querySelector('main section h1');
    if (h1 != null) {
      heroTitle = _text(h1).replaceAll('\n', ' ').trim();
      if (heroTitle.isEmpty) heroTitle = 'Колледж ДГУ';
    }
    final heroP = doc.querySelector('main section.relative.min-h-screen p');
    if (heroP != null) {
      final t = _text(heroP).trim();
      if (t.isNotEmpty) heroSubtitle = t;
    }

    var ecosystemTitle = CollegeSiteFallback.defaultContent.ecosystemTitle;
    var ecosystemSubtitle = CollegeSiteFallback.defaultContent.ecosystemSubtitle;
    for (final h2 in doc.querySelectorAll('h2')) {
      final t = _text(h2);
      if (t.contains('экосистем')) {
        ecosystemTitle = t;
        final p = h2.parent?.querySelector('p');
        if (p != null) {
          final st = _text(p).trim();
          if (st.isNotEmpty) ecosystemSubtitle = st;
        }
        break;
      }
    }

    final features = <CollegeFeatureCard>[];
    for (final h3 in doc.querySelectorAll('h3')) {
      final title = _text(h3).trim();
      if (title.isEmpty) continue;
      final card = h3.parent;
      if (card == null) continue;
      final p = card.querySelector('p');
      if (p == null) continue;
      final body = _text(p).trim();
      if (body.isEmpty) continue;
      if (features.any((f) => f.title == title)) continue;
      if (title.length > 80) continue;
      features.add(CollegeFeatureCard(title: title, body: body));
      if (features.length >= 6) break;
    }

    var directionsTitle = CollegeSiteFallback.defaultContent.directionsTitle;
    var directionsSubtitle = CollegeSiteFallback.defaultContent.directionsSubtitle;
    for (final h2 in doc.querySelectorAll('h2')) {
      final t = _text(h2);
      if (t.contains('Направления')) {
        directionsTitle = t;
        final parent = h2.parent;
        final p = parent?.querySelector('p');
        if (p != null) {
          final st = _text(p).trim();
          if (st.isNotEmpty) directionsSubtitle = st;
        }
        break;
      }
    }

    final directions = _parseDirections(doc, origin);
    final contacts = _mergeContacts(
      _parseContacts(doc),
      CollegeSiteFallback.defaultContent.contacts,
    );
    final quickLinks = _parseQuickLinks(doc, origin);

    final parsed = CollegeSiteContent(
      heroTitle: heroTitle,
      heroSubtitle: heroSubtitle,
      ecosystemTitle: ecosystemTitle,
      ecosystemSubtitle: ecosystemSubtitle,
      features: features.isNotEmpty ? features : CollegeSiteFallback.defaultContent.features,
      directionsTitle: directionsTitle,
      directionsSubtitle: directionsSubtitle,
      directions: directions.isNotEmpty ? directions : CollegeSiteFallback.defaultContent.directions,
      contacts: contacts,
      quickLinks: quickLinks.isNotEmpty ? quickLinks : CollegeSiteFallback.defaultContent.quickLinks,
      fetchedAt: fetchedAt,
    );
    return parsed;
  }

  /// Дополняет распарсенные контакты значениями по умолчанию (MAX и др.).
  static CollegeContacts _mergeContacts(CollegeContacts parsed, CollegeContacts fallback) {
    return CollegeContacts(
      address: parsed.address ?? fallback.address,
      phone: parsed.phone ?? fallback.phone,
      email: parsed.email ?? fallback.email,
      vkUrl: parsed.vkUrl ?? fallback.vkUrl,
      telegramUrl: parsed.telegramUrl ?? fallback.telegramUrl,
      maxUrl: parsed.maxUrl ?? fallback.maxUrl,
    );
  }

  static List<CollegeDirection> _parseDirections(Document doc, String origin) {
    final seen = <String>{};
    final out = <CollegeDirection>[];

    for (final a in doc.querySelectorAll('a[href*="abiturient"]')) {
      final href = a.attributes['href']?.trim() ?? '';
      if (!href.contains('dir=')) continue;
      final key = href.split('#').first;
      if (!seen.add(key)) continue;

      String? code;
      String? shortLabel;
      for (final span in a.querySelectorAll('span')) {
        final t = _text(span).trim();
        if (RegExp(r'^\d{2}\.\d{2}\.\d{2}$').hasMatch(t)) {
          code = t;
        } else if (t.isNotEmpty &&
            t != '·' &&
            !RegExp(r'^\d{2}\.\d{2}\.\d{2}$').hasMatch(t) &&
            (shortLabel == null || shortLabel.length < t.length)) {
          shortLabel = t;
        }
      }

      final h3 = a.querySelector('h3');
      final p = a.querySelector('p');
      final title = h3 != null ? _text(h3).trim() : '';
      final desc = p != null ? _text(p).trim() : '';
      if (title.isEmpty) continue;

      final img = a.querySelector('img')?.attributes['src'];
      String? imageUrl;
      if (img != null && img.isNotEmpty) {
        imageUrl = img.startsWith('http') ? img : '$origin$img';
      }

      out.add(
        CollegeDirection(
          code: code ?? '',
          shortLabel: shortLabel ?? '',
          title: title,
          description: desc,
          imageUrl: imageUrl,
          sitePath: href.startsWith('http') ? href : '$origin$href',
        ),
      );
    }
    return out;
  }

  static CollegeContacts _parseContacts(Document doc) {
    String? address;
    String? phone;
    String? email;
    String? vk;
    String? tg;
    String? max;

    for (final a in doc.querySelectorAll('footer a[href^="tel:"]')) {
      phone = _text(a).trim().isNotEmpty ? _text(a).trim() : a.attributes['href']?.replaceFirst('tel:', '');
    }
    for (final a in doc.querySelectorAll('footer a[href^="mailto:"]')) {
      email = _text(a).trim().isNotEmpty ? _text(a).trim() : a.attributes['href']?.replaceFirst('mailto:', '');
    }
    for (final li in doc.querySelectorAll('footer li')) {
      final t = _text(li);
      if (t.contains('Махачкала') || t.contains('Дзержинского')) {
        address = t.trim();
      }
    }
    for (final a in doc.querySelectorAll('footer a[href*="vk.com"]')) {
      vk = a.attributes['href'];
    }
    for (final a in doc.querySelectorAll('footer a[href*="t.me"]')) {
      tg = a.attributes['href'];
    }
    for (final a in doc.querySelectorAll('footer a[href*="max.ru"], footer a[aria-label="MAX"]')) {
      final href = a.attributes['href'];
      if (href != null && href.contains('max.ru')) {
        max = href;
        break;
      }
    }

    return CollegeContacts(
      address: address,
      phone: phone,
      email: email,
      vkUrl: vk,
      telegramUrl: tg,
      maxUrl: max,
    );
  }

  static List<CollegeQuickLink> _parseQuickLinks(Document doc, String origin) {
    final out = <CollegeQuickLink>[];
    final hero = doc.querySelector('main section.relative.min-h-screen');
    if (hero == null) return out;

    for (final a in hero.querySelectorAll('a[href]')) {
      final href = a.attributes['href']?.trim() ?? '';
      if (href.isEmpty) continue;
      final label = _text(a).trim();
      if (label.isEmpty) continue;
      final external = href.startsWith('http');
      final url = external ? href : '$origin$href';
      out.add(CollegeQuickLink(label: label, url: url, external: external, primary: label.contains('заявление')));
    }
    return out;
  }

  static String _text(Element el) => el.text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
