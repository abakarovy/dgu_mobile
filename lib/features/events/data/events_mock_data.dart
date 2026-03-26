import 'event_item.dart';

List<EventItem> eventItems() => const [
  EventItem(
    imageAsset: 'assets/images/img1.png',
    category: 'Культура',
    title: 'Студенческая весна 2026',
    description:
        'Ежегодный фестиваль творчества студентов ДГУ. Музыка, танцы, театр и многое другое.',
    dateRange: '15.04.2026 — 20.04.2026',
    location: 'Актовый зал ДГУ',
  ),
  EventItem(
    imageAsset: 'assets/images/2.png',
    category: 'Спорт',
    title: 'Весенний турнир по мини-футболу',
    description:
        'Соревнования между командами факультетов. Приходите поддержать своих!',
    dateRange: '22.04.2026',
    location: 'Спорткомплекс ДГУ',
  ),
  EventItem(
    imageAsset: 'assets/images/3.png',
    category: 'Образование',
    title: 'День открытых дверей',
    description:
        'Знакомство с программами, преподавателями и жизнью колледжа. Ответы на вопросы.',
    dateRange: '05.05.2026',
    location: 'Главный корпус',
  ),
];

