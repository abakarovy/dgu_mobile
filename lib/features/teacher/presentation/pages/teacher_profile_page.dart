import 'package:flutter/material.dart';

import '../../../staff/presentation/pages/staff_profile_page.dart';

/// Профиль преподавателя — без админских «Мои инструменты».
class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffProfilePage(mode: StaffProfileMode.teacher);
  }
}
