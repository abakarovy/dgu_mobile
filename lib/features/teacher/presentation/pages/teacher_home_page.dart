import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/person_name_format.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../features/schedule/data/schedule_lesson.dart';
import '../../../staff/presentation/widgets/staff_admin_ui.dart';
import '../widgets/teacher_shell_scaffold.dart';

/// Главная преподавателя: приветствие, расписание 1С, быстрые действия.
class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  List<ScheduleLesson> _lessons = [];
  bool _loading = true;
  String? _error;
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _readName();
    unawaited(_load());
  }

  void _readName() {
    final raw = AppContainer.jsonCache.getJsonMap('auth:me');
    if (raw != null) {
      final name = formatPersonNameDisplay(
        (raw['full_name'] ?? raw['fio'] ?? '').toString(),
      );
      if (name.isNotEmpty) _fullName = name;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lessons = await AppContainer.scheduleApi.getToday();
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить расписание';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherShellScaffold(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            StaffAdminUi.tabPaddingH,
            AppUi.spacingL,
            StaffAdminUi.tabPaddingH,
            32,
          ),
          children: [
            Text(
              _fullName.isEmpty ? 'Добрый день' : 'Здравствуйте, $_fullName',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Расписание на сегодня',
              style: AppTextStyle.inter(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            _scheduleSection(),
            const SizedBox(height: 20),
            Text(
              'Быстрые действия',
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _quickAction(
              label: 'Журнал',
              icon: Icons.grade_outlined,
              onTap: () => context.go('/teacher/journal'),
            ),
            const SizedBox(height: 8),
            _quickAction(
              label: 'Новость или мероприятие',
              icon: Icons.newspaper_outlined,
              onTap: () => context.go('/teacher/content'),
            ),
            const SizedBox(height: 8),
            _quickAction(
              label: 'Материалы',
              icon: Icons.folder_outlined,
              onTap: () => context.push('/teacher/materials'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Text(
        _error!,
        style: AppTextStyle.inter(color: AppColors.grade2Text),
      );
    }
    if (_lessons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: StaffAdminUi.cardDecoration(),
        child: Text(
          'На сегодня пар нет',
          style: AppTextStyle.inter(color: AppColors.grey),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _lessons.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _lessonCard(_lessons[i]),
        ],
      ],
    );
  }

  Widget _lessonCard(ScheduleLesson lesson) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: StaffAdminUi.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.subject,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (lesson.time.isNotEmpty) lesson.time,
              if (lesson.auditorium.isNotEmpty) lesson.auditorium,
            ].join(' · '),
            style: AppTextStyle.inter(fontSize: 13, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StaffAdminUi.cardBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.lightBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.grey.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
