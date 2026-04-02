import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_container.dart';
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
    // Всегда пробуем обновить из сети (даже если кэш есть, но пустой/старый).
    // Это важно: иначе вкладка может «застрять» на пустом кэше и не увидеть обновления.
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final showNews = _tab == NewsTab.news;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: _switcher(
        newsSelected: showNews,
        onNews: () => setState(() => _tab = NewsTab.news),
        onEvents: () => setState(() => _tab = NewsTab.events),
      ),
    );
    if (!showNews) {
      return Column(
        children: [
          header,
          const Expanded(child: EventsPage(embedded: true)),
        ],
      );
    }
    if (_loading && _items.isEmpty) {
      return Column(
        children: [
          header,
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
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
        padding: EdgeInsets.zero,
        children: [
          header,
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
                      imageWidget:
                          (_items[i].imageUrl != null && _items[i].imageUrl!.isNotEmpty)
                              ? Image.network(
                                  _items[i].imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 160,
                                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                )
                              : null,
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

  void _hydrateFromCache() {
    final cached = AppContainer.jsonCache.getJsonList(_cacheKey);
    if (cached == null) return;
    try {
      final items = cached
          .whereType<Map>()
          .map((m) => NewsModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      _items = items;
      _loading = false;
    } catch (_) {
      // ignore
    }
  }

  Future<void> _refresh() async {
    if (_loading == false && mounted) {
      // keep current list while refreshing
    }
    if (mounted) setState(() => _loading = true);
    try {
      final fresh = await AppContainer.newsApi.getNews(limit: 30);
      await AppContainer.jsonCache.setJson(_cacheKey, [for (final n in fresh) n.toJson()]);
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
