import 'package:flutter/material.dart';

import 'staff_news_admin_page.dart';

/// Админка мероприятий — тот же экран, вкладка «Мероприятия».
class StaffEventsAdminPage extends StatelessWidget {
  const StaffEventsAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffNewsAdminPage(initialTab: StaffNewsEventsTab.events);
  }
}
