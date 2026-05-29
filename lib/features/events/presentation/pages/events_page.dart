import 'dart:ui';

import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../data/event_item.dart';
import '../../../../core/di/app_container.dart';
import '../../../../data/models/event_model.dart';
import '../../../../data/models/news_model.dart';

/// Вкладка «Мероприятия»: список карточек.
class EventsPage extends StatefulWidget {
  const EventsPage({
    super.key,
    this.embedded = false,
    this.eventsDetailRoute = '/app/news/events/detail',
    this.newsTabRoute = '/app/news',
  });

  /// Если true — страница рисуется внутри `NewsPage` и не делает свою шапку-переключатель.
  final bool embedded;
  final String eventsDetailRoute;
  final String newsTabRoute;

  static const double _horizontalPadding = 24;
  static const double _cardsGap = 16;

  static const Color _titleColor = Color(0xFF003B73);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _accentGreen = Color(0xFF10B981);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final Future<List<EventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final switcher = widget.embedded
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2563EB),
                  width: 1.53,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _switcherTab(
                      label: 'Новости',
                      selected: false,
                      onTap: () => context.go(widget.newsTabRoute),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _switcherTab(
                      label: 'Мероприятия',
                      selected: true,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          );
    return FutureBuilder<List<EventModel>>(
      future: _eventsFuture,
      builder: (context, snap) {
        final events = snap.data ?? const <EventModel>[];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.embedded) switcher,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EventsPage._horizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (snap.connectionState != ConnectionState.done && events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Center(child: Text('Нет мероприятий')),
                      )
                    else
                      for (int i = 0; i < events.length; i++) ...[
                        _EventCard(
                          data: EventItem.fromEventModel(events[i]),
                          onTap: () => context.push(
                            widget.eventsDetailRoute,
                            extra: EventItem.fromEventModel(events[i]),
                          ),
                        ),
                        if (i != events.length - 1)
                          const SizedBox(height: EventsPage._cardsGap),
                      ],
                    const SizedBox(height: EventsPage._cardsGap),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _switcherTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final bg = selected ? const Color(0xFF2563EB) : Colors.transparent;
    final textColor = selected ? Colors.white : const Color(0xFF2563EB);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 10.44,
              height: 1.0,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Future<List<EventModel>> _loadEvents() async {
    const cacheKey = 'events:list';
    List<EventModel> decodeCached() {
      final cached = AppContainer.jsonCache.getJsonList(cacheKey);
      if (cached == null) return const <EventModel>[];
      return cached
          .whereType<Map<String, dynamic>>()
          .map(EventModel.fromJson)
          .toList();
    }

    final cachedFirst = decodeCached();
    if (cachedFirst.isNotEmpty) return cachedFirst;

    try {
      final fresh = await AppContainer.eventsApi.getEvents();
      if (fresh.isNotEmpty || cachedFirst.isEmpty) {
        await AppContainer.jsonCache
            .setJson(cacheKey, [for (final e in fresh) e.toJson()]);
      }
      return fresh;
    } catch (_) {
      return cachedFirst;
    }
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.data, this.onTap});

  final EventItem data;
  final VoidCallback? onTap;

  static const double _radius = 24;
  static const double _imageH = 160;

  static Widget _coverImage(EventItem data) {
    Widget noImage() => ColoredBox(
          color: AppColors.backgroundSecondary,
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: AppColors.caption,
          ),
        );
    final resolved = EventModel.resolveImageUrl(data.imageUrl);
    if (resolved != null && resolved.isNotEmpty) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => noImage(),
      );
    }
    final asset = NewsModel.bundleAssetPath(data.imageUrl);
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => noImage(),
      );
    }
    if (data.imageAsset != null && data.imageAsset!.isNotEmpty) {
      return Image.asset(
        data.imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => noImage(),
      );
    }
    return noImage();
  }

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
                  _coverImage(data),
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
                    NewsModel.stripHtmlToPlain(data.description, maxLen: 0),
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
