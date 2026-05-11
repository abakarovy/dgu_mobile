import 'dart:async';
import 'dart:ui';

import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/news_model.dart';
import '../widgets/news_html_body.dart';

/// `src` у тега `<img>` (порядок в документе сохраняем).
final RegExp _newsImgSrcRe = RegExp(
  r'<\s*img[^>]*\bsrc\s*=\s*["'']([^"'']*)["'']',
  caseSensitive: false,
);

String? _imageDedupeKey(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t.startsWith('data:')) return null;
  final a = NewsModel.bundleAssetPath(t);
  if (a != null) return 'asset:$a';
  return NewsModel.resolveImageUrl(t) ?? t;
}

/// Обложка первой, затем картинки из HTML (без data: URL), без дубликатов.
List<String> _collectNewsHeroImageSources(NewsModel item) {
  final seen = <String>{};
  final out = <String>[];
  void add(String? raw) {
    if (raw == null) return;
    final key = _imageDedupeKey(raw);
    if (key == null || seen.contains(key)) return;
    seen.add(key);
    out.add(raw.trim());
  }

  add(item.imageUrl);
  for (final m in _newsImgSrcRe.allMatches(item.content)) {
    add(m.group(1));
  }
  return out;
}

/// Убираем из HTML обычные картинки (оставляем только `data:`), раз они в карусели.
String _htmlWithoutNetworkImages(String html) {
  return html.replaceAllMapped(
    RegExp(r'<\s*img[^>]*>', caseSensitive: false),
    (m) {
      final tag = m[0]!;
      final sm = RegExp(
        r'src\s*=\s*["'']([^"'']*)["'']',
        caseSensitive: false,
      ).firstMatch(tag);
      final src = sm?.group(1)?.trim() ?? '';
      if (src.startsWith('data:')) return tag;
      return '';
    },
  );
}

Widget _newsDetailImage(String? rawUrl, double imageHeight) {
  final placeholder = Container(
    color: AppColors.backgroundSecondary,
    child: const Icon(Icons.image_outlined, size: 48, color: AppColors.caption),
  );
  final asset = NewsModel.bundleAssetPath(rawUrl);
  if (asset != null) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: imageHeight,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
  final url = NewsModel.resolveImageUrl(rawUrl);
  if (url != null && url.isNotEmpty) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: imageHeight,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
  return placeholder;
}

Future<void> _openNewsContentUrl(String url) async {
  if (url.isEmpty) return;
  final resolved = url.startsWith('http://') || url.startsWith('https://')
      ? url
      : ApiConstants.resolvePublicFileUrl(url);
  final u = Uri.tryParse(resolved);
  if (u != null && await canLaunchUrl(u)) {
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }
}

/// Экран детали новости: без аппбара, картинка 320, стрелка назад в круге, категория, дата, заголовок, текст (HTML с бэка).
class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key, required this.item});

  final NewsModel item;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safeTop = MediaQuery.paddingOf(context).top;
    final paddingH = width > 0 ? (AppUi.screenPaddingH * width / 448).clamp(16.0, 32.0) : AppUi.screenPaddingH;
    final imageHeight = width > 0 ? (AppUi.newsDetailImageHeight * width / 448).clamp(200.0, 400.0) : AppUi.newsDetailImageHeight;

    final heroSources = _collectNewsHeroImageSources(item);
    final htmlForBody = heroSources.isNotEmpty
        ? _htmlWithoutNetworkImages(item.content)
        : item.content;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _NewsDetailHero(
                  imageHeight: imageHeight,
                  sources: heroSources,
                ),
                Positioned(
                  left: paddingH,
                  top: safeTop + paddingH,
                  child: _BackButton(size: AppUi.newsDetailBackButtonSize),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(paddingH, 0, paddingH, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppUi.spacingXl),
                _CategoryAndDate(
                  category: 'Новости',
                  date: item.createdAt.toIso8601String().split('T').first,
                ),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    height: 33 / 30,
                    color: AppColors.newsDetailTitle,
                  ),
                ),
                const SizedBox(height: 24),
                if (!item.isPublished)
                  Text(
                    'Материал снят с публикации.',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.caption,
                    ),
                  )
                else if (item.content.trim().isEmpty &&
                    (item.excerpt == null || item.excerpt!.trim().isEmpty))
                  Text(
                    'Нет текста.',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      height: 26 / 16,
                      color: AppColors.caption,
                    ),
                  )
                else if (item.content.trim().isEmpty)
                  Text(
                    NewsModel.stripHtmlToPlain(item.excerpt, maxLen: 0),
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      height: 26 / 16,
                      color: AppColors.textPrimary,
                    ),
                  )
                else
                  NewsHtmlBody(
                    html: htmlForBody,
                    onLinkTap: (url) async => _openNewsContentUrl(url),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Верх детали: одна картинка или карусель (авто + свайп) при 2+.
class _NewsDetailHero extends StatelessWidget {
  const _NewsDetailHero({
    required this.imageHeight,
    required this.sources,
  });

  final double imageHeight;
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return SizedBox(
        width: double.infinity,
        height: imageHeight,
        child: _newsDetailImage(null, imageHeight),
      );
    }
    if (sources.length == 1) {
      return SizedBox(
        width: double.infinity,
        height: imageHeight,
        child: _newsDetailImage(sources.first, imageHeight),
      );
    }
    return _NewsDetailImageCarousel(
      height: imageHeight,
      sources: sources,
    );
  }
}

class _NewsDetailImageCarousel extends StatefulWidget {
  const _NewsDetailImageCarousel({
    required this.height,
    required this.sources,
  });

  final double height;
  final List<String> sources;

  @override
  State<_NewsDetailImageCarousel> createState() =>
      _NewsDetailImageCarouselState();
}

class _NewsDetailImageCarouselState extends State<_NewsDetailImageCarousel> {
  late final PageController _controller;
  Timer? _timer;
  bool _programmatic = false;

  static const Duration _anim = Duration(milliseconds: 450);
  static const Curve _curve = Curves.easeInOutCubic;

  int get _n => widget.sources.length;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _scheduleAdvance(seconds: 5);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAdvance({required int seconds}) {
    _timer?.cancel();
    if (_n <= 1) return;
    _timer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      unawaited(_goNext());
      _scheduleAdvance(seconds: 5);
    });
  }

  Future<void> _goNext() async {
    final c = _controller;
    if (!c.hasClients) return;
    _programmatic = true;
    final i = c.page?.round() ?? 0;
    await c.animateToPage(
      (i + 1) % _n,
      duration: _anim,
      curve: _curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _controller.hasClients ? (_controller.page ?? 0.0) : 0.0;
    const gap = 8.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            itemCount: _n,
            onPageChanged: (_) {
              if (_programmatic) {
                _programmatic = false;
                return;
              }
              _scheduleAdvance(seconds: 10);
            },
            itemBuilder: (context, index) {
              return SizedBox(
                width: double.infinity,
                height: widget.height,
                child: _newsDetailImage(widget.sources[index], widget.height),
              );
            },
          ),
        ),
        const SizedBox(height: gap),
        Center(child: _NewsCarouselDots(page: page, slideCount: _n)),
        const SizedBox(height: gap),
      ],
    );
  }
}

class _NewsCarouselDots extends StatelessWidget {
  const _NewsCarouselDots({
    required this.page,
    required this.slideCount,
  });

  final double page;
  final int slideCount;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    const pillH = 6.0;
    const d = 6.0;
    const color = AppColors.primaryBlue;
    final inactive = color.withValues(alpha: 0.35);
    const gap = 6.0;
    const pillW = 22.0;
    final n = slideCount < 1 ? 1 : slideCount;

    if (n == 1) {
      return SizedBox(
        width: pillW,
        height: pillH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    final floor = page.floor();
    final t = (page - floor).clamp(0.0, 1.0);
    final fromSlide = floor % n;
    final toSlide = (floor + 1) % n;

    final widths = List<double>.filled(n, d);
    widths[fromSlide] = _lerp(pillW, d, t);
    widths[toSlide] = _lerp(d, pillW, t);

    Color dotColor(int i) {
      if (i == fromSlide) return Color.lerp(color, inactive, t) ?? inactive;
      if (i == toSlide) return Color.lerp(inactive, color, t) ?? color;
      return inactive;
    }

    final lefts = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      lefts[i] = lefts[i - 1] + widths[i - 1] + gap;
    }
    final totalW = widths.reduce((a, b) => a + b) + gap * (n - 1);

    return SizedBox(
      width: totalW,
      height: pillH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < n; i++)
            Positioned(
              left: lefts[i],
              top: 0,
              child: Container(
                width: widths[i],
                height: pillH,
                decoration: BoxDecoration(
                  color: dotColor(i),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppUi.newsDetailBackBlurSigma, sigmaY: AppUi.newsDetailBackBlurSigma),
        child: Material(
          color: const Color(0x33000000),
          child: InkWell(
            onTap: () => context.pop(),
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: AppUi.newsDetailBackIconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryAndDate extends StatelessWidget {
  const _CategoryAndDate({required this.category, required this.date});

  final String category;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          category.toUpperCase(),
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            height: 1.0,
            letterSpacing: 1,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 8),
        SvgPicture.asset(
          'assets/icons/schedule_icon.svg',
          width: 12,
          height: 12,
          colorFilter: const ColorFilter.mode(AppColors.caption, BlendMode.srcIn),
        ),
        const SizedBox(width: 4),
        Text(
          date,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            height: 1.0,
            color: AppColors.caption,
          ),
        ),
      ],
    );
  }
}
