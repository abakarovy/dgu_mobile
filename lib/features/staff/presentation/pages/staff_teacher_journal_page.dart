import 'package:flutter/material.dart';

import '../../../teacher/presentation/pages/teacher_journal_page.dart';

/// Legacy-маршрут `/staff/journal` — для преподавателя основной вход `/teacher/journal`.
class StaffTeacherJournalPage extends StatelessWidget {
  const StaffTeacherJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeacherJournalPage(embeddedInShell: false);
  }
}
