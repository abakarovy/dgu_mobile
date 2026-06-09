import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/college_site/college_site_image_prefetch.dart';
import '../../../../data/college_site/college_site_content.dart';
import '../../../../data/college_site/college_site_fallback.dart';
/// Главная гостевого режима — контент college.dgu.ru (MOBILE_PUBLIC_SITE_DATA.md).
class PublicHomePage extends StatefulWidget {
  const PublicHomePage({super.key});

  @override
  State<PublicHomePage> createState() => _PublicHomePageState();
}

/// Совместимость со старыми маршрутами.
class ApplicantHomePage extends PublicHomePage {
  const ApplicantHomePage({super.key});
}

class _PublicHomePageState extends State<PublicHomePage> {
  static const double _uiScaleBoost = 1.2;

  late final CollegeSiteContent _content = _contentForYear();

  CollegeSiteContent _contentForYear() {
    final base = CollegeSiteFallback.defaultContent;
    return CollegeSiteContent(
      heroTitle: base.heroTitle,
      heroSubtitle: base.heroSubtitle,
      ecosystemTitle: base.ecosystemTitle,
      ecosystemSubtitle: base.ecosystemSubtitle,
      features: base.features,
      directionsTitle: base.directionsTitle,
      directionsSubtitle: base.directionsSubtitle,
      directions: base.directions,
      contacts: base.contacts,
      quickLinks: base.quickLinks,
      fetchedAt: null,
    );
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMaps(String address) async {
    final query = Uri.encodeComponent(address.trim());
    if (query.isEmpty) return;

    final candidates = <Uri>[
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
        Uri.parse('http://maps.apple.com/?q=$query'),
      Uri.parse('geo:0,0?q=$query'),
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      Uri.parse('https://yandex.ru/maps/?text=$query'),
    ];

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
  }

  CollegeContacts _contactsForDisplay() {
    final parsed = _content.contacts;
    final fb = CollegeSiteFallback.defaultContent.contacts;
    return CollegeContacts(
      address: parsed.address ?? fb.address,
      phone: parsed.phone ?? fb.phone,
      email: parsed.email ?? fb.email,
      vkUrl: parsed.vkUrl ?? fb.vkUrl,
      telegramUrl: parsed.telegramUrl ?? fb.telegramUrl,
      maxUrl: parsed.maxUrl ?? fb.maxUrl,
    );
  }

  double _sf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return min(size.width / 402, size.height / 874) * _uiScaleBoost;
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    final sf = _sf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
            stops: [0.0, 0.22, 0.5],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppUi.spacingM),
                    _HeroBanner(content: content, sf: sf),
                    SizedBox(height: AppUi.spacingL),
                    _buildQuickLinks(content),
                    SizedBox(height: AppUi.spacingXl),
                    _SectionHeader(
                      title: content.ecosystemTitle,
                      subtitle: content.ecosystemSubtitle,
                    ),
                    SizedBox(height: AppUi.spacingM),
                    for (var i = 0; i < content.features.length; i++) ...[
                      _FeatureCard(feature: content.features[i], index: i),
                      if (i != content.features.length - 1) SizedBox(height: AppUi.spacingM),
                    ],
                    SizedBox(height: AppUi.spacingXl),
                    _SectionHeader(
                      title: content.directionsTitle,
                      subtitle: content.directionsSubtitle,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppUi.spacingM),
              _DirectionsAutoCarousel(
                directions: content.directions,
                onTap: (d) {
                  _openUrl(
                    d.sitePath ??
                        '${ApiConstants.collegeSiteOrigin}/abiturient#directions',
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppUi.spacingXl),
                    const _SectionHeader(title: 'Контакты'),
                    SizedBox(height: AppUi.spacingM),
                    _ContactsCard(
                      contacts: _contactsForDisplay(),
                      onOpen: _openUrl,
                      onOpenMaps: _openMaps,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQuickLink(CollegeQuickLink link) {
    final route = link.inAppRoute;
    if (route != null && route.isNotEmpty) {
      context.push(route);
      return;
    }
    if (link.url.isNotEmpty) {
      unawaited(_openUrl(link.url));
    }
  }

  Widget _buildQuickLinks(CollegeSiteContent content) {
    final links = content.quickLinks;
    if (links.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < links.length; i++) ...[
          if (i > 0) const SizedBox(height: AppUi.spacingM),
          _QuickActionCard(
            link: links[i],
            onTap: () => _onQuickLink(links[i]),
          ),
        ],
      ],
    );
  }
}

/// Горизонтальная лента направлений — непрерывная зацикленная прокрутка.
class _DirectionsAutoCarousel extends StatefulWidget {
  const _DirectionsAutoCarousel({
    required this.directions,
    required this.onTap,
  });

  final List<CollegeDirection> directions;
  final void Function(CollegeDirection direction) onTap;

  @override
  State<_DirectionsAutoCarousel> createState() => _DirectionsAutoCarouselState();
}

class _DirectionsAutoCarouselState extends State<_DirectionsAutoCarousel>
    with SingleTickerProviderStateMixin {
  static const double _cardWidth = 272;
  static const double _step = _cardWidth + AppUi.spacingM;
  static const double _pixelsPerSecond = 60;
  static const Duration _resumeAfterInteraction = Duration(seconds: 4);

  final ScrollController _controller = ScrollController();
  Ticker? _ticker;
  Timer? _resumeTimer;
  Duration? _lastTick;
  bool _userInteracting = false;
  static const int _loopCopies = 3;

  int get _count => widget.directions.length;
  double get _loopWidth => _count * _step;

  @override
  void initState() {
    super.initState();
    if (_count < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) _controller.jumpTo(_loopWidth);
    });
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant _DirectionsAutoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.directions.length != widget.directions.length) {
      _lastTick = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients && _count >= 2) {
          _controller.jumpTo(_loopWidth);
        }
      });
    }
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _ticker?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _pauseAutoScroll() {
    if (_userInteracting) return;
    _userInteracting = true;
    _lastTick = null;
    _resumeTimer?.cancel();
  }

  void _scheduleResume() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeAfterInteraction, () {
      if (!mounted) return;
      _userInteracting = false;
      _lastTick = null;
      _normalizeScrollPosition();
    });
  }

  void _normalizeScrollPosition() {
    if (!_controller.hasClients || _count < 2) return;
    var offset = _controller.offset;
    while (offset >= _loopWidth * 2) {
      offset -= _loopWidth;
    }
    while (offset < _loopWidth) {
      offset += _loopWidth;
    }
    _controller.jumpTo(offset);
  }

  void _onTick(Duration elapsed) {
    if (_userInteracting || !_controller.hasClients || _count < 2) return;
    final prev = _lastTick;
    _lastTick = elapsed;
    if (prev == null) return;

    final dt = (elapsed - prev).inMicroseconds / 1e6;
    var next = _controller.offset + _pixelsPerSecond * dt;

    // Держим позицию во второй копии списка для бесшовного цикла.
    while (next >= _loopWidth * 2) {
      next -= _loopWidth;
    }
    while (next < _loopWidth) {
      next += _loopWidth;
    }

    _controller.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.directions.isEmpty) return const SizedBox.shrink();
    if (_count < 2) {
      return SizedBox(
        height: 268,
        width: _cardWidth,
        child: _DirectionCard(
          direction: widget.directions.first,
          onTap: () => widget.onTap(widget.directions.first),
        ),
      );
    }

    final total = _count * _loopCopies;
    final hPad = AppUi.screenPaddingH;

    return SizedBox(
      height: 268,
      width: MediaQuery.sizeOf(context).width,
      child: Listener(
        onPointerDown: (_) => _pauseAutoScroll(),
        onPointerUp: (_) => _scheduleResume(),
        onPointerCancel: (_) => _scheduleResume(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is UserScrollNotification) {
              _pauseAutoScroll();
            } else if (notification is ScrollEndNotification) {
              _normalizeScrollPosition();
              _scheduleResume();
            }
            return false;
          },
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            scrollCacheExtent: const ScrollCacheExtent.pixels(800),
            padding: EdgeInsets.symmetric(horizontal: hPad),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: total,
          separatorBuilder: (_, _) => const SizedBox(width: AppUi.spacingM),
          itemBuilder: (context, i) {
            final d = widget.directions[i % _count];
            return SizedBox(
              width: _cardWidth,
              height: 268,
              child: _DirectionCard(
                direction: d,
                onTap: () => widget.onTap(d),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.content, required this.sf});

  final CollegeSiteContent content;
  final double sf;

  @override
  Widget build(BuildContext context) {
    final radius = 20.0 * sf;
    final pad = 20.0 * sf;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDBEAFE),
            offset: Offset(0, 5.12 * sf),
            blurRadius: 6.4 * sf,
            spreadRadius: -3.84 * sf,
          ),
          BoxShadow(
            color: const Color(0xFFDBEAFE),
            offset: Offset(0, 12.8 * sf),
            blurRadius: 16 * sf,
            spreadRadius: -3.2 * sf,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -36 * sf,
            right: 24 * sf,
            child: Container(
              width: 100 * sf,
              height: 100 * sf,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20 * sf,
            left: -16 * sf,
            child: Container(
              width: 72 * sf,
              height: 72 * sf,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/image_home.png',
              width: 118 * sf,
              height: 134 * sf,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad + 72 * sf, pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * sf, vertical: 5 * sf),
                  decoration: BoxDecoration(
                    color: AppColors.chipBackgroundOnBanner,
                    borderRadius: BorderRadius.circular(20 * sf),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, size: 13 * sf, color: AppColors.textOnBanner),
                      SizedBox(width: 5 * sf),
                      Text(
                        'Колледж ДГУ',
                        style: AppTextStyle.inter(
                          fontSize: 11 * sf,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnBanner,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14 * sf),
                Text(
                  content.heroSubtitle,
                  style: AppTextStyle.inter(
                    fontSize: 14 * sf,
                    height: 1.45,
                    color: AppColors.textOnBanner.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: subtitle != null && subtitle!.isNotEmpty ? 44 : 22,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppUi.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: AppUi.spacingXs),
                Text(
                  subtitle!,
                  style: AppTextStyle.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.notificationSubtitle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.link, required this.onTap});

  final CollegeQuickLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = link.primary;
    final inApp = link.inAppRoute != null && link.inAppRoute!.isNotEmpty;
    final icon = primary
        ? Icons.edit_document
        : (inApp ? Icons.account_balance_outlined : Icons.open_in_new_rounded);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        child: Ink(
          padding: const EdgeInsets.all(AppUi.spacingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppUi.radiusL),
            gradient: primary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                  )
                : null,
            color: primary ? null : Colors.white,
            border: primary ? null : Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: (primary ? AppColors.lightBlue : Colors.black).withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.backgroundBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: primary ? Colors.white : AppColors.lightBlue,
                ),
              ),
              const SizedBox(width: AppUi.spacingM),
              Expanded(
                child: Text(
                  link.label,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.3,
                    color: primary ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (inApp)
                Icon(
                  Icons.chevron_right_rounded,
                  color: primary ? Colors.white.withValues(alpha: 0.9) : AppColors.lightBlue,
                )
              else
                Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: primary
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.lightBlue.withValues(alpha: 0.85),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.index});

  final CollegeFeatureCard feature;
  final int index;

  static IconData _iconFor(int i) {
    return switch (i % 3) {
      0 => Icons.verified_user_outlined,
      1 => Icons.route_outlined,
      _ => Icons.devices_outlined,
    };
  }

  static Color _iconColorFor(int i) {
    return switch (i % 3) {
      0 => AppColors.lightBlue,
      1 => AppColors.primaryGreen,
      _ => const Color(0xFF7C3AED),
    };
  }

  static Color _iconBgFor(int i) {
    return switch (i % 3) {
      0 => AppColors.backgroundBlue,
      1 => AppColors.backgroundGreen,
      _ => const Color(0xFFF5F3FF),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(AppUi.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconBgFor(index),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(index), size: 22, color: _iconColorFor(index)),
          ),
          const SizedBox(width: AppUi.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppUi.spacingS),
                Text(
                  feature.body,
                  style: AppTextStyle.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.notificationSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionCard extends StatelessWidget {
  const _DirectionCard({required this.direction, required this.onTap});

  final CollegeDirection direction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppUi.radiusL),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 96,
                child: direction.imageUrl != null
                    ? Image(
                        image: CollegeSiteImagePrefetch.directionThumbProvider(
                          direction.imageUrl!,
                        ),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => _directionImageFallback(),
                      )
                    : _directionImageFallback(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppUi.spacingM,
                    10,
                    AppUi.spacingM,
                    AppUi.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (direction.code.isNotEmpty) ...[
                        _Chip(text: direction.code),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        direction.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          direction.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.inter(
                            fontSize: 12,
                            height: 1.3,
                            color: AppColors.notificationSubtitle,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Подробнее',
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.lightBlue,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.lightBlue.withValues(alpha: 0.85),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _directionImageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.school_outlined, color: AppColors.lightBlue, size: 40),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlue,
        borderRadius: BorderRadius.circular(AppUi.taskChipRadius),
      ),
      child: Text(
        text,
        style: AppTextStyle.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.lightBlue,
        ),
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({
    required this.contacts,
    required this.onOpen,
    required this.onOpenMaps,
  });

  final CollegeContacts contacts;
  final Future<void> Function(String url) onOpen;
  final Future<void> Function(String address) onOpenMaps;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          if (contacts.address != null)
            _ContactRow(
              description: 'Адрес',
              title: contacts.address!,
              iconPath: 'assets/icons/location.svg',
              iconColor: AppColors.supportTelIcon,
              iconBg: AppColors.supportTelIconBg,
              onTap: () => onOpenMaps(contacts.address!),
            ),
          if (contacts.phone != null) ...[
            if (contacts.address != null) const SizedBox(height: 10),
            _ContactRow(
              description: 'Телефон',
              title: contacts.phone!,
              iconPath: 'assets/icons/tel.svg',
              iconColor: AppColors.supportTelIcon,
              iconBg: AppColors.supportTelIconBg,
              onTap: () => onOpen(
                'tel:${contacts.phone!.replaceAll(RegExp(r'[^\d+]'), '')}',
              ),
            ),
          ],
          if (contacts.email != null) ...[
            const SizedBox(height: 10),
            _ContactRow(
              description: 'Email',
              title: contacts.email!,
              iconPath: 'assets/icons/mail.svg',
              iconColor: AppColors.supportMailIcon,
              iconBg: AppColors.supportMailIconBg,
              onTap: () => onOpen('mailto:${contacts.email}'),
            ),
          ],
          if (contacts.vkUrl != null) ...[
            const SizedBox(height: 10),
            _ContactRow(
              description: 'Соцсеть',
              title: 'ВКонтакте',
              iconPath: 'assets/icons/internet.svg',
              iconColor: AppColors.supportInternetIcon,
              iconBg: AppColors.supportInternetIconBg,
              onTap: () => onOpen(contacts.vkUrl!),
            ),
          ],
          if (contacts.telegramUrl != null) ...[
            const SizedBox(height: 10),
            _ContactRow(
              description: 'Соцсеть',
              title: 'Telegram',
              iconPath: 'assets/icons/internet.svg',
              iconColor: AppColors.supportInternetIcon,
              iconBg: AppColors.supportInternetIconBg,
              onTap: () => onOpen(contacts.telegramUrl!),
            ),
          ],
          if (contacts.maxUrl != null) ...[
            const SizedBox(height: 10),
            _ContactRow(
              description: 'Соцсеть',
              title: 'MAX',
              iconPath: 'assets/icons/internet.svg',
              iconColor: AppColors.supportInternetIcon,
              iconBg: AppColors.supportInternetIconBg,
              onTap: () => onOpen(contacts.maxUrl!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.description,
    required this.title,
    required this.iconPath,
    this.iconColor = AppColors.supportContactTitle,
    this.iconBg = AppColors.supportContactIconBg,
    this.onTap,
  });

  final String description;
  final String title;
  final String iconPath;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppUi.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUi.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppUi.spacingM,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppUi.supportContactIconPadding),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppUi.profileRowIconRadius),
                ),
                child: SvgPicture.asset(
                  iconPath,
                  width: AppUi.supportContactIconSize,
                  height: AppUi.supportContactIconSize,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: AppUi.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description.toUpperCase(),
                      style: AppTextStyle.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.caption,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                SvgPicture.asset(
                  'assets/icons/chevron_right.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.chevronRight,
                    BlendMode.srcIn,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
