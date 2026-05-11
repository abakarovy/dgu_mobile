import 'dart:async';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// HTML-текст новости: инлайн `style` (размер, шрифт, цвет, жирность) + ссылки.
/// Не зависит от парсера CSS в flutter_html.
class NewsHtmlBody extends StatefulWidget {
  const NewsHtmlBody({
    super.key,
    required this.html,
    this.onLinkTap,
    this.blockSpacing = 10,
  });

  final String html;
  final Future<void> Function(String url)? onLinkTap;
  final double blockSpacing;

  @override
  State<NewsHtmlBody> createState() => _NewsHtmlBodyState();
}

class _NewsHtmlBodyState extends State<NewsHtmlBody> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final doc = html_parser.parse(widget.html);
    final body = doc.body;
    if (body == null) {
      return const SizedBox.shrink();
    }

    final base = _Ctx.base();
    final blocks = _topLevelBlocks(body.nodes, base, context);
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  List<Widget> _topLevelBlocks(
    List<dom.Node> nodes,
    _Ctx parentCtx,
    BuildContext context,
  ) {
    final out = <Widget>[];
    for (final n in nodes) {
      if (n is dom.Text) {
        if (n.text.trim().isEmpty) continue;
        out.add(
          Padding(
            padding: EdgeInsets.only(bottom: widget.blockSpacing),
            child: Text.rich(TextSpan(text: n.text, style: _toTextStyle(parentCtx))),
          ),
        );
      } else if (n is dom.Element) {
        final w = _elementToBlock(n, parentCtx, context);
        if (w != null) out.add(w);
      }
    }
    return out;
  }

  Widget? _elementToBlock(dom.Element e, _Ctx parentCtx, BuildContext context) {
    final tag = e.localName?.toLowerCase() ?? '';
    switch (tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final ctx = _mergeStyleAttr(_ctxForHeading(tag, parentCtx), e.attributes['style']);
        final spans = _inlineSpans(e.nodes, ctx, context);
        if (spans.isEmpty) return null;
        return Padding(
          padding: EdgeInsets.only(bottom: widget.blockSpacing + 2),
          child: Text.rich(TextSpan(children: spans)),
        );
      case 'p':
        final ctx = _mergeStyleAttr(_Ctx.paragraph(parentCtx), e.attributes['style']);
        final spans = _inlineSpans(e.nodes, ctx, context);
        if (spans.isEmpty) return null;
        return Padding(
          padding: EdgeInsets.only(bottom: widget.blockSpacing),
          child: Text.rich(TextSpan(children: spans)),
        );
      case 'blockquote':
      case 'article':
      case 'section':
      case 'div':
        final nested = _topLevelBlocks(e.nodes, parentCtx, context);
        if (nested.isEmpty) return null;
        return Padding(
          padding: EdgeInsets.only(bottom: widget.blockSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nested,
          ),
        );
      case 'ul':
        return _buildUl(e, parentCtx, context);
      case 'ol':
        return _buildOl(e, parentCtx, context);
      case 'img':
      case 'script':
      case 'style':
      case 'head':
        return null;
      default:
        final nested = _topLevelBlocks(e.nodes, parentCtx, context);
        if (nested.isEmpty) return null;
        return Padding(
          padding: EdgeInsets.only(bottom: widget.blockSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nested,
          ),
        );
    }
  }

  Widget _buildUl(dom.Element e, _Ctx parentCtx, BuildContext context) {
    final rows = <Widget>[];
    for (final li in e.children.where((c) => c.localName?.toLowerCase() == 'li')) {
      final spans = _inlineSpans(li.nodes, parentCtx, context);
      if (spans.isEmpty) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: _toTextStyle(parentCtx)),
              Expanded(child: Text.rich(TextSpan(children: spans))),
            ],
          ),
        ),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: widget.blockSpacing),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _buildOl(dom.Element e, _Ctx parentCtx, BuildContext context) {
    final rows = <Widget>[];
    var index = 0;
    for (final li in e.children.where((c) => c.localName?.toLowerCase() == 'li')) {
      index++;
      final spans = _inlineSpans(li.nodes, parentCtx, context);
      if (spans.isEmpty) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text('$index. ', style: _toTextStyle(parentCtx)),
              ),
              Expanded(child: Text.rich(TextSpan(children: spans))),
            ],
          ),
        ),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: widget.blockSpacing),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  List<InlineSpan> _inlineSpans(
    List<dom.Node> nodes,
    _Ctx ctx,
    BuildContext context,
  ) {
    final out = <InlineSpan>[];
    for (final n in nodes) {
      if (n is dom.Text) {
        final t = n.text;
        if (t.isEmpty) continue;
        out.add(TextSpan(text: t, style: _toTextStyle(ctx)));
      } else if (n is dom.Element) {
        out.addAll(_inlineElement(n, ctx, context));
      }
    }
    return out;
  }

  List<InlineSpan> _inlineElement(dom.Element e, _Ctx ctx, BuildContext context) {
    final tag = e.localName?.toLowerCase() ?? '';
    switch (tag) {
      case 'br':
        return [TextSpan(text: '\n', style: _toTextStyle(ctx))];
      case 'strong':
      case 'b':
        var c = ctx.copyWith(fontWeight: FontWeight.w700);
        c = _mergeStyleAttr(c, e.attributes['style']);
        return [
          TextSpan(
            style: _toTextStyle(c),
            children: _inlineSpans(e.nodes, c, context),
          ),
        ];
      case 'em':
      case 'i':
        var c = ctx.copyWith(fontStyle: FontStyle.italic);
        c = _mergeStyleAttr(c, e.attributes['style']);
        return [
          TextSpan(
            style: _toTextStyle(c),
            children: _inlineSpans(e.nodes, c, context),
          ),
        ];
      case 'u':
        var c = ctx.copyWith(decoration: TextDecoration.underline);
        c = _mergeStyleAttr(c, e.attributes['style']);
        return [
          TextSpan(
            style: _toTextStyle(c),
            children: _inlineSpans(e.nodes, c, context),
          ),
        ];
      case 'span':
        final merged = _mergeStyleAttr(ctx, e.attributes['style']);
        return [
          TextSpan(
            style: _toTextStyle(merged),
            children: _inlineSpans(e.nodes, merged, context),
          ),
        ];
      case 'a':
        final href = e.attributes['href'] ?? '';
        var c = ctx.copyWith(
          color: AppColors.primaryBlue,
          decoration: TextDecoration.underline,
        );
        c = _mergeStyleAttr(c, e.attributes['style']);
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (href.isEmpty) return;
            final cb = widget.onLinkTap;
            if (cb != null) unawaited(cb(href));
          };
        _recognizers.add(recognizer);
        return [
          TextSpan(
            style: _toTextStyle(c),
            children: _inlineSpans(e.nodes, c, context),
            recognizer: recognizer,
          ),
        ];
      case 'img':
      case 'script':
      case 'style':
        return [];
      default:
        final merged = _mergeStyleAttr(ctx, e.attributes['style']);
        return [
          TextSpan(
            style: _toTextStyle(merged),
            children: _inlineSpans(e.nodes, merged, context),
          ),
        ];
    }
  }

  static _Ctx _ctxForHeading(String tag, _Ctx parent) {
    switch (tag) {
      case 'h1':
        return parent.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.newsDetailTitle,
        );
      case 'h2':
        return parent.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.newsDetailTitle,
        );
      case 'h3':
        return parent.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.newsDetailTitle,
        );
      case 'h4':
        return parent.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.newsDetailTitle,
        );
      case 'h5':
        return parent.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.newsDetailTitle,
        );
      default:
        return parent.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.newsDetailTitle,
        );
    }
  }

  static TextStyle _toTextStyle(_Ctx ctx) {
    return _bundledNewsFontTextStyle(ctx);
  }

  /// Первый кусок из `font-family: "Times New Roman", serif` — без кавычек, lower case.
  static String _normalizeCssFontFamily(String? fam) {
    if (fam == null) return '';
    return fam
        .split(',')
        .first
        .toLowerCase()
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
  }

  /// Имена из редактора на сайте — проприетарные web-шрифты; в приложении — [pubspec] `fonts:` из `assets/fonts/news_editor/`.
  static TextStyle _bundledNewsFontTextStyle(_Ctx ctx) {
    final base = TextStyle(
      fontSize: ctx.fontSize,
      fontWeight: ctx.fontWeight,
      fontStyle: ctx.fontStyle,
      color: ctx.color,
      decoration: ctx.decoration,
    );
    final key = _normalizeCssFontFamily(ctx.cssFontFamily);

    if (key.isEmpty) {
      return base.copyWith(fontFamily: 'Inter');
    }
    if (key.contains('comic')) {
      return base.copyWith(fontFamily: 'ComicNeue');
    }
    if (key.contains('courier')) {
      return base.copyWith(fontFamily: 'LiberationMono');
    }
    if (key.contains('georgia')) {
      return base.copyWith(fontFamily: 'CharisSIL');
    }
    if (key.contains('lucida')) {
      return base.copyWith(fontFamily: 'Andika');
    }
    if (key.contains('tahoma')) {
      return base.copyWith(fontFamily: 'DejaVuSansCondensed');
    }
    if (key.contains('times')) {
      return base.copyWith(fontFamily: 'LiberationSerif');
    }
    if (key.contains('trebuchet')) {
      return base.copyWith(fontFamily: 'Overpass');
    }
    if (key.contains('verdana')) {
      return base.copyWith(fontFamily: 'DejaVuSans');
    }
    if (key.contains('sans serif') || key == 'sans-serif' || key == 'sans') {
      return base.copyWith(fontFamily: 'Inter');
    }
    if (key.contains('roboto') && !key.contains('mono')) {
      return base.copyWith(fontFamily: 'Inter');
    }
    if (key.contains('open sans')) {
      return base.copyWith(fontFamily: 'Andika');
    }
    if (key.contains('merriweather')) {
      return base.copyWith(fontFamily: 'CharisSIL');
    }
    if (key.contains('mono')) {
      return base.copyWith(fontFamily: 'LiberationMono');
    }
    if (key.contains('lora')) {
      return base.copyWith(fontFamily: 'LiberationSerif');
    }
    if (key.contains('montserrat')) {
      return base.copyWith(fontFamily: 'Montserrat');
    }
    return base.copyWith(fontFamily: 'Inter');
  }

  static _Ctx _mergeStyleAttr(_Ctx ctx, String? styleAttr) {
    if (styleAttr == null || styleAttr.trim().isEmpty) return ctx;
    final s = styleAttr;
    var next = ctx;

    final fsPx = RegExp(
      r'font-size\s*:\s*(\d+(?:\.\d+)?)\s*px',
      caseSensitive: false,
    ).firstMatch(s);
    final fsPt = RegExp(
      r'font-size\s*:\s*(\d+(?:\.\d+)?)\s*pt',
      caseSensitive: false,
    ).firstMatch(s);
    final fsEm = RegExp(
      r'font-size\s*:\s*(\d+(?:\.\d+)?)\s*em',
      caseSensitive: false,
    ).firstMatch(s);
    if (fsPx != null) {
      final v = double.tryParse(fsPx.group(1)!);
      if (v != null) next = next.copyWith(fontSize: v);
    } else if (fsPt != null) {
      final v = double.tryParse(fsPt.group(1)!);
      if (v != null) next = next.copyWith(fontSize: v * 1.3333333333);
    } else if (fsEm != null) {
      final v = double.tryParse(fsEm.group(1)!);
      if (v != null) next = next.copyWith(fontSize: next.fontSize * v);
    }

    final ff = RegExp(
      r'font-family\s*:\s*([^;]+)',
      caseSensitive: false,
    ).firstMatch(s);
    if (ff != null) {
      final raw = ff.group(1)!.split(',').first.trim();
      if (raw.isNotEmpty) {
        next = next.copyWith(cssFontFamily: raw);
      }
    }

    if (RegExp(r'font-weight\s*:\s*bold', caseSensitive: false).hasMatch(s) ||
        RegExp(r'font-weight\s*:\s*700', caseSensitive: false).hasMatch(s)) {
      next = next.copyWith(fontWeight: FontWeight.w700);
    } else {
      final fwNum = RegExp(
        r'font-weight\s*:\s*(\d+)',
        caseSensitive: false,
      ).firstMatch(s);
      if (fwNum != null) {
        final n = int.tryParse(fwNum.group(1)!);
        if (n != null) next = next.copyWith(fontWeight: _fontWeightFromCssInt(n));
      }
    }

    if (RegExp(r'font-style\s*:\s*italic', caseSensitive: false).hasMatch(s)) {
      next = next.copyWith(fontStyle: FontStyle.italic);
    }

    final hex = RegExp(
      r'color\s*:\s*#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})',
      caseSensitive: false,
    ).firstMatch(s);
    if (hex != null) {
      final parsed = _parseHexColor(hex.group(1)!);
      if (parsed != null) next = next.copyWith(color: parsed);
    }

    if (RegExp(r'text-decoration\s*:\s*underline', caseSensitive: false)
        .hasMatch(s)) {
      next = next.copyWith(decoration: TextDecoration.underline);
    }

    return next;
  }

  static Color? _parseHexColor(String input) {
    var h = input;
    if (h.length == 3) {
      final r = h[0], g = h[1], b = h[2];
      h = '$r$r$g$g$b$b';
    }
    if (h.length != 6) return null;
    final v = int.tryParse(h, radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }

  static FontWeight _fontWeightFromCssInt(int n) {
    final v = (((n.clamp(1, 1000) + 50) ~/ 100) * 100).clamp(100, 900);
    return switch (v) {
      100 => FontWeight.w100,
      200 => FontWeight.w200,
      300 => FontWeight.w300,
      400 => FontWeight.w400,
      500 => FontWeight.w500,
      600 => FontWeight.w600,
      700 => FontWeight.w700,
      800 => FontWeight.w800,
      900 => FontWeight.w900,
      _ => FontWeight.w400,
    };
  }
}

class _Ctx {
  _Ctx({
    required this.fontSize,
    required this.fontWeight,
    required this.fontStyle,
    required this.color,
    required this.cssFontFamily,
    required this.decoration,
  });

  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final Color color;
  final String? cssFontFamily;
  final TextDecoration decoration;

  factory _Ctx.base() {
    return _Ctx(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: AppColors.textPrimary,
      cssFontFamily: null,
      decoration: TextDecoration.none,
    );
  }

  factory _Ctx.paragraph(_Ctx parent) {
    return parent.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    );
  }

  _Ctx copyWith({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    String? cssFontFamily,
    bool clearFontFamily = false,
    TextDecoration? decoration,
  }) {
    return _Ctx(
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      color: color ?? this.color,
      cssFontFamily: clearFontFamily ? null : (cssFontFamily ?? this.cssFontFamily),
      decoration: decoration ?? this.decoration,
    );
  }
}
