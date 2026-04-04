import 'dart:async';

import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_container.dart';
import '../../../../core/navigation/news_header_host.dart';
import '../../../../core/navigation/news_refresh_host.dart';
import '../../../../data/models/news_model.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../events/presentation/pages/events_page.dart';
import '../widgets/news_card.dart';

/// Вкладка «Новости» — список карточек новостей.
class NewsPage extends StatefulWidget {
  const NewsPage({
    super.key,
    this.initialTab = NewsTab.news,
  });

  final NewsTab initialTab;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  static const _cacheKey = 'news:list';
  List<NewsModel> _items = const <NewsModel>[];
  /// Первый запуск: нет ни кэша, ни ответа сети — показываем индикатор в теле.
  bool _loading = true;
  late NewsTab _tab;

  static Widget _switcher({
    required bool newsSelected,
    required VoidCallback onNews,
    required VoidCallback onEvents,
  }) {
    return Container(
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
              selected: newsSelected,
              onTap: onNews,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _switcherTab(
              label: 'Мероприятия',
              selected: !newsSelected,
              onTap: onEvents,
            ),
          ),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _hydrateFromCache();
    _refresh();
    NewsRefreshHost.register(
      () {
        if (!mounted) return;
        unawaited(_refresh());
      },
    );
  }

  @override
  void dispose() {
    NewsRefreshHost.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showNews = _tab == NewsTab.news;
    final headerTitle = showNews ? 'Новости' : 'Мероприятия';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NewsHeaderHost.setTitle(headerTitle);
    });

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: _switcher(
        newsSelected: showNews,
        onNews: () => setState(() => _tab = NewsTab.news),
        onEvents: () => setState(() => _tab = NewsTab.events),
      ),
    );

    return ColoredBox(
      color: Colors.white,
      child: showNews
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Expanded(child: _buildNewsContent()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const Expanded(child: EventsPage(embedded: true)),
              ],
            ),
    );
  }

  Widget _buildNewsContent() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppUi.screenPaddingAll.copyWith(top: 0),
          children: const [
            SizedBox(height: 24),
            Center(child: Text('Нет новостей')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: AppUi.screenPaddingAll.copyWith(top: 0),
            child: Column(
              children: [
                for (var i = 0; i < _items.length; i++) ...[
                  Align(
                    alignment: Alignment.topCenter,
                    child: NewsCard(
                      category: 'Новости',
                      title: _items[i].title,
                      excerpt: _items[i].excerpt ?? '',
                      date: _items[i].createdAt.toIso8601String().split('T').first,
                      imageWidget: _buildNewsImage(_items[i].imageUrl),
                      onTap: () =>
                          context.push('/app/news/detail', extra: _items[i]),
                    ),
                  ),
                  if (i != _items.length - 1)
                    const SizedBox(height: AppUi.spacingBetweenNews),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildNewsImage(String? rawUrl) {
    final asset = NewsModel.bundleAssetPath(rawUrl);
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 160,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }
    final url = NewsModel.resolveImageUrl(rawUrl);
    if (url == null || url.isEmpty) return null;
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 160,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  void _hydrateFromCache() {
    final cached = AppContainer.jsonCache.getJsonList(_cacheKey);
    if (cached == null) {
      _items = const <NewsModel>[];
      _loading = true;
      return;
    }
    try {
      final items = cached
          .whereType<Map>()
          .map((m) => NewsModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      _items = items;
      _loading = false;
    } catch (_) {
      _items = const <NewsModel>[];
      _loading = true;
    }
  }

  Future<void> _refresh() async {
    // Не включаем полноэкранную загрузку, если уже показали кэш (в т.ч. пустой []):
    // обновление идёт в фоне, список не прячется.
    try {
      final fresh = await AppContainer.newsApi.getNews(limit: 30);
      await AppContainer.jsonCache.setJson(
        _cacheKey,
        [for (final n in fresh) n.toJson()],
      );
      if (!mounted) return;
      setState(() {
        _items = fresh;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }
}

enum NewsTab { news, events }
