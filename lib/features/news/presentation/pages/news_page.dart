import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_container.dart';
import '../../../../data/models/news_model.dart';
import '../widgets/news_card.dart';

/// Вкладка «Новости» — список карточек новостей.
class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  static const _cacheKey = 'news:list';
  List<NewsModel> _items = const <NewsModel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
    // Всегда пробуем обновить из сети (даже если кэш есть, но пустой/старый).
    // Это важно: иначе вкладка может «застрять» на пустом кэше и не увидеть обновления.
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: AppUi.screenPaddingAll,
          children: const [
            SizedBox(height: 24),
            Center(child: Text('Нет новостей')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: AppUi.screenPaddingAll,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppUi.spacingBetweenNews),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Align(
            alignment: Alignment.topCenter,
            child: NewsCard(
              category: 'Новости',
              title: item.title,
              excerpt: item.excerpt ?? '',
              date: item.createdAt.toIso8601String().split('T').first,
              imageWidget: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 160,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    )
                  : null,
              onTap: () => context.push('/app/news/detail', extra: item),
            ),
          );
        },
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
