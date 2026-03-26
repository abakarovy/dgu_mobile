/// Одно задание для отображения (пока без бэка).
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

