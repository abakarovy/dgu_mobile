import 'package:flutter/material.dart';

import '../../../staff/presentation/widgets/staff_admin_ui.dart';

/// Фон вкладки внутри [TeacherShellPage] (без вложенного Scaffold).
class TeacherShellScaffold extends StatelessWidget {
  const TeacherShellScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StaffAdminUi.bg,
      child: child,
    );
  }
}
