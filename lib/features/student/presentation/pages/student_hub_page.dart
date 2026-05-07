import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/student/academic_period.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/features/student/presentation/widgets/student_module_tile.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Хаб студенческих сервисов (курсы, объявления, портфолио, рейтинг, портал).
class StudentHubPage extends StatefulWidget {
  const StudentHubPage({super.key});

  static const Color _cLms = Color(0xFF7C3AED);
  static const Color _cAnn = Color(0xFFEA580C);
  static const Color _cPort = Color(0xFF0891B2);
  static const Color _cSch = Color(0xFFCA8A04);
  static const Color _cPortal = Color(0xFF2563EB);

  @override
  State<StudentHubPage> createState() => _StudentHubPageState();
}

class _StudentHubPageState extends State<StudentHubPage> {
  late AcademicPeriod _period;
  bool _schLoading = true;
  Map<String, dynamic> _schSummary = {};

  static String _categoryLabel(String key) {
    switch (key) {
      case 'study':
        return 'Учёба';
      case 'science':
        return 'Наука';
      case 'society':
        return 'Общество';
      case 'culture':
        return 'Культура';
      case 'sport':
        return 'Спорт';
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _period = AcademicPeriod.current();
    _loadScholarshipSummary();
  }

  Future<void> _loadScholarshipSummary() async {
    setState(() => _schLoading = true);
    try {
      final s = await AppContainer.studentServicesApi.scholarshipMySummary(
        academicYear: _period.academicYear,
        semester: _period.semester,
      );
      if (mounted) setState(() => _schSummary = s);
    } catch (_) {
      if (mounted) setState(() => _schSummary = {});
    } finally {
      if (mounted) setState(() => _schLoading = false);
    }
  }

  Widget _scholarshipPreviewCard(BuildContext context) {
    final approved = _schSummary['total_approved'];
    final approvedStr = approved != null ? '$approved' : '—';
    final cats = _schSummary['category_totals'];
    final buf = StringBuffer();
    if (cats is Map) {
      for (final e in cats.entries) {
        final k = '${e.key}';
        final v = e.value;
        if (buf.isNotEmpty) buf.write(' · ');
        buf.write('${_categoryLabel(k)}: $v');
      }
    }
    final catLine = buf.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => context.push('/app/student/scholarship'),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: StudentHubPage._cSch.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.emoji_events_outlined, color: StudentHubPage._cSch, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Стипендиальный рейтинг',
                          style: AppTextStyle.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_period.academicYear}, ${_period.semesterLabelRu} семестр',
                          style: AppTextStyle.inter(
                            fontSize: 12,
                            color: AppColors.notificationSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.chevronRight, size: 24),
                ],
              ),
              const SizedBox(height: 14),
              if (_schLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else ...[
                Text(
                  'Утверждено баллов',
                  style: AppTextStyle.inter(fontSize: 12, color: AppColors.notificationSubtitle),
                ),
                const SizedBox(height: 4),
                Text(
                  approvedStr,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (catLine.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    catLine,
                    style: AppTextStyle.inter(fontSize: 12, height: 1.35, color: AppColors.grey),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Критерии и заявки — в полном разделе',
                  style: AppTextStyle.inter(
                    fontSize: 12,
                    color: const Color(0xFFCA8A04),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppHeader(
              leading: appHeaderNestedBackLeading(context),
              headerTitle: Text('Сервисы студента', style: appHeaderNestedTitleStyle),
            ),
            body: RefreshIndicator(
              onRefresh: _loadScholarshipSummary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _scholarshipPreviewCard(context),
                  StudentModuleTile(
                    icon: Icons.school_outlined,
                    title: 'Мои курсы',
                    subtitle: 'Юрайт, ПРОФ СПО, Академия Москва, учебный план',
                    accentColor: StudentHubPage._cLms,
                    onTap: () => context.push('/app/student/lms'),
                  ),
                  StudentModuleTile(
                    icon: Icons.campaign_outlined,
                    title: 'Объявления отделения',
                    subtitle: 'Сообщения для вашей учебной группы',
                    accentColor: StudentHubPage._cAnn,
                    onTap: () => context.push('/app/student/announcements'),
                  ),
                  StudentModuleTile(
                    icon: Icons.folder_shared_outlined,
                    title: 'Портфолио',
                    subtitle: 'Загрузки, баллы, публичная ссылка',
                    accentColor: StudentHubPage._cPort,
                    onTap: () => context.push('/app/student/portfolio'),
                  ),
                  StudentModuleTile(
                    icon: Icons.public_outlined,
                    title: 'Раздел «Студентам»',
                    subtitle: 'PDF расписаний, ВПР, ресурсы с портала',
                    accentColor: StudentHubPage._cPortal,
                    onTap: () => context.push('/app/student/portal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
