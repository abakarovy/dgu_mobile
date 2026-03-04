import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/news_mock_data.dart';
import '../widgets/news_card.dart';

/// Вкладка «Новости» — список карточек новостей.
class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = newsItems();
    return ListView.separated(
      padding: AppUi.screenPaddingAll,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppUi.spacingBetweenNews),
      itemBuilder: (context, index) {
        final item = items[index];
        return Align(
          alignment: Alignment.topCenter,
          child: NewsCard(
            category: item.category,
            title: item.title,
            excerpt: item.excerpt,
            date: item.date,
            imageWidget: Image.asset(
              item.imageAsset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 160,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            onTap: () => context.push('/app/news/detail', extra: item),
          ),
        );
      },
    );
  }
}
