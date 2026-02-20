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
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _items[index];
        return NewsCard(
          category: item.category,
          title: item.title,
          excerpt: item.excerpt,
          date: item.date,
          onTap: () {},
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
