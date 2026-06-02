import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/college_site/college_site_content.dart';
import '../../../../data/college_site/college_site_fallback.dart';
/// Главная гостевого режима — контент college.dgu.ru (MOBILE_PUBLIC_SITE_DATA.md).
class PublicHomePage extends StatefulWidget {
  const PublicHomePage({super.key});

  static const Color kBlue = Color(0xFF2E63D5);

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
    final year = DateTime.now().year;
    return CollegeSiteContent(
      heroTitle: 'Колледж ДГУ $year',
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
      child: ColoredBox(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppUi.spacingL),
              _HeroBanner(content: content, sf: sf),
              SizedBox(height: AppUi.spacingXl),
              _buildQuickLinks(content),
              SizedBox(height: AppUi.spacingXl),
              _sectionTitle(content.ecosystemTitle, subtitle: content.ecosystemSubtitle),
              SizedBox(height: AppUi.spacingM),
              for (var i = 0; i < content.features.length; i++) ...[
                _FeatureCard(feature: content.features[i]),
                if (i != content.features.length - 1) SizedBox(height: AppUi.spacingM),
              ],
              SizedBox(height: 28),
              _sectionTitle(content.directionsTitle, subtitle: content.directionsSubtitle),
              SizedBox(height: AppUi.spacingM),
              for (var i = 0; i < content.directions.length; i++) ...[
                _DirectionTile(
                  direction: content.directions[i],
                  onTap: () {
                    final d = content.directions[i];
                    _openUrl(
                      d.sitePath ??
                          '${ApiConstants.collegeSiteOrigin}/abiturient#directions',
                    );
                  },
                ),
                if (i != content.directions.length - 1) SizedBox(height: AppUi.spacingM),
              ],
              SizedBox(height: 28),
              _sectionTitle('Контакты'),
              SizedBox(height: AppUi.spacingM),
              _ContactsCard(
                contacts: _contactsForDisplay(),
                onOpen: _openUrl,
                onOpenMaps: _openMaps,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: 24 / 18,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          SizedBox(height: AppUi.spacingXs),
          Text(
            subtitle,
            style: AppTextStyle.inter(
              fontSize: 14,
              height: 1.4,
              color: AppColors.notificationSubtitle,
            ),
          ),
        ],
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < content.quickLinks.length; i++) ...[
          if (i > 0) SizedBox(height: AppUi.spacingM),
          _QuickLinkButton(
            link: content.quickLinks[i],
            onTap: () => _onQuickLink(content.quickLinks[i]),
          ),
        ],
      ],
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
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/image_home.png',
              width: 108 * sf,
              height: 123 * sf,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * sf, vertical: 4 * sf),
                  decoration: BoxDecoration(
                    color: AppColors.chipBackgroundOnBanner,
                    borderRadius: BorderRadius.circular(20 * sf),
                  ),
                  child: Text(
                    'Колледж ДГУ',
                    style: AppTextStyle.inter(
                      fontSize: 11 * sf,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnBanner,
                    ),
                  ),
                ),
                SizedBox(height: 12 * sf),
                Text(
                  content.heroTitle,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 22 * sf,
                    height: 1.2,
                    color: AppColors.textOnBanner,
                  ),
                ),
                SizedBox(height: 8 * sf),
                Text(
                  content.heroSubtitle,
                  style: AppTextStyle.inter(
                    fontSize: 13 * sf,
                    height: 1.4,
                    color: AppColors.textOnBanner.withValues(alpha: 0.88),
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final CollegeFeatureCard feature;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(AppUi.spacingL),
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
          SizedBox(height: AppUi.spacingS),
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
    );
  }
}

class _DirectionTile extends StatelessWidget {
  const _DirectionTile({required this.direction, required this.onTap});

  final CollegeDirection direction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (direction.imageUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    direction.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _directionImageFallback(),
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _directionImageFallback(),
                ),
              Padding(
                padding: const EdgeInsets.all(AppUi.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (direction.code.isNotEmpty || direction.shortLabel.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (direction.code.isNotEmpty) _Chip(text: direction.code),
                          if (direction.shortLabel.isNotEmpty)
                            _Chip(text: direction.shortLabel, muted: true),
                        ],
                      ),
                    if (direction.code.isNotEmpty || direction.shortLabel.isNotEmpty)
                      SizedBox(height: AppUi.spacingS),
                    Text(
                      direction.title,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppUi.spacingS),
                    Text(
                      direction.description,
                      style: AppTextStyle.inter(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.notificationSubtitle,
                      ),
                    ),
                    SizedBox(height: AppUi.spacingM),
                    Row(
                      children: [
                        Text(
                          'Подробнее на сайте',
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: PublicHomePage.kBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: PublicHomePage.kBlue.withValues(alpha: 0.8),
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
    );
  }

  Widget _directionImageFallback() {
    return Container(
      color: AppColors.backgroundSecondary,
      child: const Center(
        child: Icon(Icons.school_outlined, color: AppColors.lightBlue, size: 48),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted ? AppColors.backgroundSecondary : AppColors.backgroundBlue,
        borderRadius: BorderRadius.circular(AppUi.taskChipRadius),
      ),
      child: Text(
        text,
        style: AppTextStyle.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: muted ? AppColors.grey : AppColors.lightBlue,
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  const _QuickLinkButton({required this.link, required this.onTap});

  final CollegeQuickLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = link.primary;
    final inApp = link.inAppRoute != null && link.inAppRoute!.isNotEmpty;
    return SizedBox(
      height: 52,
      child: primary
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: PublicHomePage.kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(46),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      link.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  if (!inApp) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.open_in_new_rounded, size: 18),
                  ],
                ],
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: PublicHomePage.kBlue,
                side: const BorderSide(color: PublicHomePage.kBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(46),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      link.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  if (inApp) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ],
              ),
            ),
    );
  }
}
