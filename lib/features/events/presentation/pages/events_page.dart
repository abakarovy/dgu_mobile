import 'dart:async';
import 'dart:ui';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../data/event_item.dart';
import '../../data/events_mock_data.dart';

/// Вкладка «Мероприятия»: карусель и индикаторы.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  static const List<String> _imageAssets = [
    'assets/images/img1.png',
    'assets/images/2.png',
    'assets/images/3.png',
  ];

  static const int _kImageCount = 3;
  /// Кратно 3, чтобы при открытии был первый слайд (картинка 1.png, индекс 0 mod 3).
  static const int _kInitialPage = 100002;

  static const double _afterAppBarGap = 20;
  static const double _horizontalPadding = 24;
  static const double _imageWidth = 400;
  static const double _imageHeight = 225;
  static const double _imageRadius = 24;
  static const double _afterCarouselGap = 16;
  static const double _carouselItemGap = 12;
  static const double _afterIndicatorsToHeaderGap = 24;
  static const double _afterHeaderGap = 16;
  static const double _cardsGap = 16;

  static const double _dotGap = 6;
  static const double _pillWidth = 24;
  static const double _pillHeight = 6;
  static const double _inactiveDotSize = 6;
  static const Color _indicatorColor = Color(0xFF003B73);
  static const Color _titleColor = Color(0xFF003B73);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _accentGreen = Color(0xFF10B981);

  /// Общие с `animateToPage`: индикатор читает тот же `page`, что и [PageView].
  static const Duration kCarouselAnimationDuration = Duration(milliseconds: 450);
  static const Curve kCarouselAnimationCurve = Curves.easeInOutCubic;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final PageController _pageController;
  Timer? _timer;
  bool _programmaticAdvance = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: EventsPage._kInitialPage,
      // Keep full-width; we add visible gap via per-page padding.
      viewportFraction: 1,
    );
    _pageController.addListener(_onPageScroll);
    _scheduleNextAdvance(seconds: 5);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    if (mounted) setState(() {});
  }

  void _scheduleNextAdvance({required int seconds}) {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      _advanceProgrammatically();
      _scheduleNextAdvance(seconds: 5);
    });
  }

  void _onUserChangedPage() {
    _scheduleNextAdvance(seconds: 10);
  }

  Future<void> _advanceProgrammatically() async {
    final c = _pageController;
    if (!c.hasClients) return;
    _programmaticAdvance = true;
    final current = c.page?.round() ?? EventsPage._kInitialPage;
    await c.animateToPage(
      current + 1,
      duration: EventsPage.kCarouselAnimationDuration,
      curve: EventsPage.kCarouselAnimationCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final innerW = maxW - EventsPage._horizontalPadding * 2;
        final imageW = innerW < EventsPage._imageWidth
            ? innerW
            : EventsPage._imageWidth;

        final page = _pageController.hasClients
            ? (_pageController.page ?? EventsPage._kInitialPage.toDouble())
            : EventsPage._kInitialPage.toDouble();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EventsPage._horizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: EventsPage._afterAppBarGap),
                SizedBox(
                  height: EventsPage._imageHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (_) {
                      if (_programmaticAdvance) {
                        _programmaticAdvance = false;
                        return;
                      }
                      _onUserChangedPage();
                    },
                    itemBuilder: (context, index) {
                      final i = index % EventsPage._kImageCount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EventsPage._carouselItemGap / 2,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            EventsPage._imageRadius,
                          ),
                          child: SizedBox(
                            width: imageW,
                            height: EventsPage._imageHeight,
                            child: Image.asset(
                              EventsPage._imageAssets[i],
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) =>
                                  ColoredBox(
                                color: AppColors.backgroundSecondary,
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: AppColors.caption,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: EventsPage._afterCarouselGap),
                Center(
                  child: _EventDotsIndicator(page: page),
                ),
                const SizedBox(height: EventsPage._afterIndicatorsToHeaderGap),
                Text(
                  'Все события',
                  textAlign: TextAlign.left,
                  style: AppTextStyle.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                    color: EventsPage._titleColor,
                  ),
                ),
                const SizedBox(height: EventsPage._afterHeaderGap),
                for (int i = 0; i < _events.length; i++) ...[
                  _EventCard(
                    data: _events[i],
                    onTap: () => context.push('/app/events/detail', extra: _events[i]),
                  ),
                  if (i != _events.length - 1)
                    const SizedBox(height: EventsPage._cardsGap),
                ],
                const SizedBox(height: EventsPage._cardsGap),
              ],
            ),
          ),
        );
      },
    );
  }
}

final List<EventItem> _events = eventItems();

class _EventCard extends StatelessWidget {
  const _EventCard({required this.data, this.onTap});

  final EventItem data;
  final VoidCallback? onTap;

  static const double _radius = 24;
  static const double _imageH = 160;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 20,
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
            SizedBox(
              height: _imageH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    data.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: AppColors.backgroundSecondary,
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: AppColors.caption,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 14,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(33554400),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          color: const Color(0xE5FFFFFF),
                          child: Text(
                            data.category.toUpperCase(),
                            style: AppTextStyle.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 15 / 10,
                              letterSpacing: 0,
                              color: EventsPage._titleColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 20 / 16,
                      color: EventsPage._titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      color: EventsPage._mutedTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/calendar.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          EventsPage._accentGreen,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data.dateRange.toUpperCase(),
                        style: AppTextStyle.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 15 / 10,
                          letterSpacing: 0.5,
                          color: EventsPage._mutedTextColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SvgPicture.asset(
                        'assets/icons/location.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          EventsPage._accentGreen,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data.location.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 15 / 10,
                            letterSpacing: 0.5,
                            color: EventsPage._mutedTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Индикаторы синхронны с [PageView]: прогресс `t = page - floor(page)` общий.
///
/// Важно: зазор [EventsPage._dotGap] (6px) считается от **краёв текущих элементов**.
/// Поэтому когда активный индикатор шире (24px), соседние элементы раздвигаются так,
/// чтобы расстояние между ними оставалось 6px.
class _EventDotsIndicator extends StatelessWidget {
  const _EventDotsIndicator({required this.page});

  final double page;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    const pillH = EventsPage._pillHeight;
    const d = EventsPage._inactiveDotSize;
    const color = EventsPage._indicatorColor;
    final inactive = color.withValues(alpha: 0.35);
    const gap = EventsPage._dotGap;
    const pillW = EventsPage._pillWidth;
    const n = EventsPage._kImageCount;

    final floor = page.floor();
    final t = (page - floor).clamp(0.0, 1.0);
    final fromSlide = floor % n;
    final toSlide = (floor + 1) % n;

    // Во время перехода: "from" сжимается 24→6, "to" расширяется 6→24.
    final widths = List<double>.filled(n, d);
    widths[fromSlide] = _lerp(pillW, d, t);
    widths[toSlide] = _lerp(d, pillW, t);

    // Цвет также плавно меняем, чтобы визуально совпадало с движением.
    Color itemColor(int i) {
      if (i == fromSlide) return Color.lerp(color, inactive, t) ?? inactive;
      if (i == toSlide) return Color.lerp(inactive, color, t) ?? color;
      return inactive;
    }

    final lefts = List<double>.filled(n, 0);
    for (int i = 1; i < n; i++) {
      lefts[i] = lefts[i - 1] + widths[i - 1] + gap;
    }
    final totalW = widths.reduce((a, b) => a + b) + gap * (n - 1);

    return SizedBox(
      width: totalW,
      height: pillH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < n; i++)
            Positioned(
              left: lefts[i],
              top: 0,
              child: Container(
                width: widths[i],
                height: pillH,
                decoration: BoxDecoration(
                  color: itemColor(i),
                  borderRadius: BorderRadius.circular(33554400),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
