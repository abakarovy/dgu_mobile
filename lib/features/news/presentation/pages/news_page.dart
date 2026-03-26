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
  late final Future<List<NewsModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsModel>>(
      future: _future,
      builder: (context, snap) {
        final items = snap.data ?? const <NewsModel>[];
        if (snap.connectionState != ConnectionState.done && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return const Center(child: Text('Нет новостей'));
        }
        return ListView.separated(
          padding: AppUi.screenPaddingAll,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppUi.spacingBetweenNews),
          itemBuilder: (context, index) {
            final item = items[index];
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
        );
      },
    );
  }

  Future<List<NewsModel>> _loadNews() async {
    const cacheKey = 'news:list';
    final cached = AppContainer.jsonCache.getJsonList(cacheKey);
    if (cached != null) {
      return cached
          .whereType<Map<String, dynamic>>()
          .map(NewsModel.fromJson)
          .toList();
    }
    // Если кэша нет — один раз загрузим сетью и сохраним.
    final fresh = await AppContainer.newsApi.getNews(limit: 30);
    await AppContainer.jsonCache.setJson(cacheKey, [for (final n in fresh) n.toJson()]);
    return fresh;
  }
}
