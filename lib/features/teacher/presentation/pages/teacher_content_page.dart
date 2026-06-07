import 'package:flutter/material.dart';

import '../../../staff/presentation/pages/staff_news_admin_page.dart';

/// Новости и мероприятия для преподавателя — тот же UI, без удаления.
class TeacherContentPage extends StatelessWidget {
  const TeacherContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffNewsAdminPage(
      embeddedInShell: true,
      showDeleteActions: false,
    );
  }
}
