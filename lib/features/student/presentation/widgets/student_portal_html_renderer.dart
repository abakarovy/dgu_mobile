import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Разбирает `body_html` с портала и рисует нативные блоки (не «стену» HTML).
class StudentPortalHtmlRenderer extends StatelessWidget {
  const StudentPortalHtmlRenderer({
    super.key,
    required this.html,
    required this.onOpenUrl,
    this.linkAccent = const Color(0xFF2563EB),
    this.bottomSpacing = 10,
  });

  final String html;
  final Future<void> Function(String url) onOpenUrl;
  final Color linkAccent;
  final double bottomSpacing;

  static bool hasMeaningfulContent(String? html) {
    if (html == null || html.trim().isEmpty) return false;
    return _plainText(html).isNotEmpty;
  }

  /// Ссылки из HTML (для дедупликации при необходимости).
  static Set<String> linkHrefs(String html) {
    final fragment = html_parser.parseFragment(html);
    final hrefs = <String>{};
    for (final a in fragment.querySelectorAll('a')) {
      final href = a.attributes['href']?.trim();
      if (href != null && href.isNotEmpty) hrefs.add(_resolveHref(href));
    }
    return hrefs;
  }

  static String _plainText(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _resolveHref(String href) {
    final h = href.trim();
    if (h.startsWith('http://') || h.startsWith('https://')) return h;
    return ApiConstants.resolvePortalHref(h);
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(html);
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: bottomSpacing * 0.4),
          _buildBlock(blocks[i]),
        ],
      ],
    );
  }

  List<_PortalBlock> _parseBlocks(String raw) {
    final fragment = html_parser.parseFragment(raw);
    final out = <_PortalBlock>[];
    _walkNodes(fragment.nodes, out);
    return out;
  }

  void _walkNodes(List<dom.Node> nodes, List<_PortalBlock> out) {
    for (final node in nodes) {
      if (node is! dom.Element) continue;
      switch (node.localName) {
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
          _addHeading(node, out);
        case 'p':
          _addParagraph(node, out);
        case 'ul':
        case 'ol':
          _addList(node, out);
        case 'a':
          _addAnchor(node, out);
        case 'br':
          break;
        case 'div':
        case 'section':
        case 'article':
          _walkNodes(node.nodes, out);
        default:
          if (node.children.isEmpty) {
            final t = node.text.trim();
            if (t.isNotEmpty) out.add(_PortalText(t));
          } else {
            _walkNodes(node.nodes, out);
          }
      }
    }
  }

  void _addHeading(dom.Element el, List<_PortalBlock> out) {
    final text = el.text.trim();
    if (text.isEmpty) return;
    final level = switch (el.localName) {
      'h1' => 1,
      'h3' => 3,
      'h4' => 4,
      _ => 2,
    };
    out.add(_PortalHeading(text, level));
  }

  void _addParagraph(dom.Element el, List<_PortalBlock> out) {
    final anchors = el.querySelectorAll('a');
    if (anchors.isNotEmpty) {
      for (final a in anchors) {
        _addAnchor(a, out);
      }
      final plain = el.text.trim();
      if (plain.isNotEmpty && anchors.every((a) => plain != a.text.trim())) {
        // Текст вокруг ссылок — отдельным абзацем без дублирования подписей ссылок.
        final linkTexts = anchors.map((a) => a.text.trim()).where((t) => t.isNotEmpty).toSet();
        var rest = plain;
        for (final lt in linkTexts) {
          rest = rest.replaceAll(lt, '').trim();
        }
        rest = rest.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (rest.isNotEmpty) out.add(_PortalText(rest));
      }
      return;
    }
    final text = el.text.trim();
    if (text.isNotEmpty) out.add(_PortalText(text));
  }

  void _addList(dom.Element list, List<_PortalBlock> out) {
    for (final li in list.children.whereType<dom.Element>().where((n) => n.localName == 'li')) {
      final liEl = li;
      final anchor = liEl.querySelector('a');
      if (anchor != null) {
        _addAnchor(anchor, out);
        continue;
      }
      final text = liEl.text.trim();
      if (text.isNotEmpty) out.add(_PortalBullet(text));
    }
  }

  void _addAnchor(dom.Element a, List<_PortalBlock> out) {
    final href = a.attributes['href']?.trim();
    if (href == null || href.isEmpty) return;
    final label = a.text.trim();
    if (label.isEmpty) return;
    final key = '$label|$href';
    if (out.whereType<_PortalLink>().any((l) => '${l.label}|${l.href}' == key)) return;
    out.add(_PortalLink(label: label, href: href));
  }

  Widget _buildBlock(_PortalBlock block) {
    return switch (block) {
      _PortalHeading(:final text, :final level) => Padding(
          padding: EdgeInsets.only(top: level <= 2 ? 4 : 2, bottom: 6),
          child: Text(
            text,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: level == 1 ? 17 : level == 2 ? 16 : 15,
              height: 1.25,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      _PortalText(:final text) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            text,
            style: AppTextStyle.inter(
              fontSize: 14,
              height: 1.5,
              color: AppColors.notificationSubtitle,
            ),
          ),
        ),
      _PortalBullet(:final text) => Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 10),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: linkAccent.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyle.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      _PortalLink(:final label, :final href) => Padding(
          padding: EdgeInsets.only(bottom: bottomSpacing),
          child: _LinkTile(
            accent: linkAccent,
            title: label,
            onTap: () => onOpenUrl(_resolveHref(href)),
          ),
        ),
    };
  }
}

sealed class _PortalBlock {}

final class _PortalHeading extends _PortalBlock {
  _PortalHeading(this.text, this.level);
  final String text;
  final int level;
}

final class _PortalText extends _PortalBlock {
  _PortalText(this.text);
  final String text;
}

final class _PortalBullet extends _PortalBlock {
  _PortalBullet(this.text);
  final String text;
}

final class _PortalLink extends _PortalBlock {
  _PortalLink({required this.label, required this.href});
  final String label;
  final String href;
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.accent,
    required this.title,
    required this.onTap,
  });

  final Color accent;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                  color: accent,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.open_in_new_rounded, color: accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.25,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppColors.chevronRight, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
