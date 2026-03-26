import 'dart:async';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Вкладка «Мероприятия»: карусель и индикаторы.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  static const List<String> _imageAssets = [
    'assets/images/1.png',
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

  static const double _dotGap = 6;
  static const double _pillWidth = 24;
  static const double _pillHeight = 6;
  static const double _inactiveDotSize = 6;
  /// Один сегмент ленты: [круг][6][место под капсулу 24][6][круг] — как в макете, 48px.
  static const double _dotSegmentWidth =
      _inactiveDotSize + _dotGap + _pillWidth + _dotGap + _inactiveDotSize;
  static const Color _indicatorColor = Color(0xFF003B73);

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
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
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
                      return Center(
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
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Вьюпорт 48px. Кружки — на ленте с тем же сдвигом, что и раньше (бесконечная прокрутка).
/// Капсула — отдельный слой: позиция `12 + frac * seg` (frac — дробная часть [page]),
/// поэтому при свайпе она едет вправо вместе с переходом слайда, а не «прилипает» к центру.
class _EventDotsIndicator extends StatelessWidget {
  const _EventDotsIndicator({required this.page});

  final double page;

  @override
  Widget build(BuildContext context) {
    const pillH = EventsPage._pillHeight;
    const d = EventsPage._inactiveDotSize;
    const color = EventsPage._indicatorColor;
    final inactive = color.withValues(alpha: 0.35);
    const seg = EventsPage._dotSegmentWidth;

    final minSeg = page.floor() - 4;
    final maxSeg = page.ceil() + 4;
    final frac = page - page.floor();
    final pillLeft = d + EventsPage._dotGap + frac * seg;

    return SizedBox(
      width: seg,
      height: pillH,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(-(page - minSeg) * seg, 0),
              child: SizedBox(
                width: (maxSeg - minSeg + 1) * seg,
                height: pillH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int s = minSeg; s <= maxSeg; s++)
                      Positioned(
                        left: (s - minSeg) * seg,
                        top: 0,
                        width: seg,
                        height: pillH,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: _InactiveDot(size: d, color: inactive),
                            ),
                            Positioned(
                              left: seg - d,
                              top: 0,
                              child: _InactiveDot(size: d, color: inactive),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: pillLeft,
              top: 0,
              child: Container(
                width: EventsPage._pillWidth,
                height: pillH,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(33554400),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InactiveDot extends StatelessWidget {
  const _InactiveDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
