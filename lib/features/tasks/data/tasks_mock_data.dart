/// Одно задание для списка (активное или завершённое).
class TaskItem {
  const TaskItem({
    required this.subjectName,
    required this.title,
    required this.deadlineText,
  });

  final String subjectName;
  final String title;
  final String deadlineText;
}

List<TaskItem> activeTasks() => [
  const TaskItem(
    subjectName: 'Веб разработка',
    title: 'Лабораторная работа №3 — верстка макета',
    deadlineText: 'До завтра, 23:59',
  ),
  const TaskItem(
    subjectName: 'Базы данных',
    title: 'Проектирование схемы БД',
    deadlineText: 'До 20 мая',
  ),
  const TaskItem(
    subjectName: 'Математика',
    title: 'Контрольная работа по теме «Интегралы»',
    deadlineText: 'До 15 мая',
  ),
];

List<TaskItem> completedTasks() => [
  const TaskItem(
    subjectName: 'Веб разработка',
    title: 'Лабораторная работа №2',
    deadlineText: 'Сдано 28 апр',
  ),
  const TaskItem(
    subjectName: 'Программирование',
    title: 'Домашнее задание — циклы',
    deadlineText: 'Сдано 25 апр',
  ),
];
