import 'package:dgu_mobile/core/constants/app_ui.dart';
import 'package:flutter/material.dart';

import '../widgets/news_card.dart';

/// Вкладка «Новости» — список карточек новостей.
class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  static const List<_NewsItem> _items = [
    _NewsItem(
      category: 'Мероприятия',
      title: 'Хакатон "Цифровая Эволюция ДГУ"',
      excerpt:
          'Приглашаем всех студентов IT-направлений принять участие в главном '
          'событии весны. Призовой фонд...',
      date: '15 Мая 2024',
    ),
    _NewsItem(
      category: 'Объявления',
      title: 'Запись на курсы по программированию',
      excerpt:
          'Открыта запись на дополнительные курсы по Python и веб-разработке. '
          'Занятия начнутся с 1 сентября.',
      date: '20 Августа 2024',
    ),
    _NewsItem(
      category: 'Мероприятия',
      title: 'День открытых дверей',
      excerpt:
          'Колледж ДГУ приглашает абитуриентов и родителей на день открытых дверей. '
          'Знакомство с направлениями и преподавателями.',
      date: '10 Сентября 2024',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppUi.screenPaddingAll,
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppUi.spacingBetweenNews),
      itemBuilder: (context, index) {
        final item = _items[index];
        final imageAsset = index % 2 == 0 ? 'assets/images/img1.png' : 'assets/images/img2.png';
        return Align(
          alignment: Alignment.topCenter,
          child: NewsCard(
            category: item.category,
            title: item.title,
            excerpt: item.excerpt,
            date: item.date,
            imageWidget: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 160,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}

class _NewsItem {
  const _NewsItem({
    required this.category,
    required this.title,
    required this.excerpt,
    required this.date,
  });
  final String category;
  final String title;
  final String excerpt;
  final String date;
}
