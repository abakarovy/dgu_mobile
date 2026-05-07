import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/realtime/student_modules_refresh.dart';
import 'package:dgu_mobile/core/student/academic_period.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/features/student/presentation/pages/scholarship_section_page.dart';
import 'package:dgu_mobile/features/student/presentation/scholarship_catalog_groups.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Подпись статуса заявки стипендиального рейтинга для UI (API отдаёт латиницей).
String scholarshipRatingEntryStatusRu(Object? raw) {
  if (raw == null) return '—';
  final s = raw.toString().trim().toLowerCase();
  if (s.isEmpty) return '—';
  return switch (s) {
    'approved' => 'Одобрено',
    'pending' => 'На рассмотрении',
    'rejected' => 'Отклонено',
    'draft' => 'Черновик',
    'cancelled' || 'canceled' => 'Отменено',
    'submitted' => 'Подана',
    'processing' || 'in_progress' => 'В обработке',
    'under_review' || 'in_review' || 'review' => 'На проверке',
    'need_revision' || 'revision_requested' => 'Нужны уточнения',
    'withdrawn' => 'Отозвана',
    _ => raw.toString().trim(),
  };
}

class ScholarshipRatingPage extends StatefulWidget {
  const ScholarshipRatingPage({super.key});

  @override
  State<ScholarshipRatingPage> createState() => _ScholarshipRatingPageState();
}

class _ScholarshipRatingPageState extends State<ScholarshipRatingPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _catalog = const [];
  Map<String, dynamic> _summary = {};
  String _year = '2025-2026';
  String _sem = '1';

  late final VoidCallback _scholarshipWsListener;

  String get _semesterForApi =>
      AcademicPeriod(academicYear: _year, semester: _sem).normalizedSemester;

  @override
  void initState() {
    super.initState();
    final p = AcademicPeriod.current();
    _year = p.academicYear;
    _sem = p.semester;
    _scholarshipWsListener = () {
      if (mounted) _load();
    };
    StudentModulesRefreshBus.scholarshipRatingTick.addListener(_scholarshipWsListener);
    _load();
  }

  @override
  void dispose() {
    StudentModulesRefreshBus.scholarshipRatingTick.removeListener(_scholarshipWsListener);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await AppContainer.studentServicesApi.scholarshipCatalog();
      final s = await AppContainer.studentServicesApi.scholarshipMySummary(
        academicYear: _year,
        semester: _semesterForApi,
      );
      if (mounted) {
        setState(() {
          _catalog = c;
          _summary = s;
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openSection(ScholarshipCatalogGroup g) {
    context.pushNamed(
      'studentScholarshipSection',
      extra: ScholarshipSectionExtra(
        sectionRef: g.ref,
        sectionTitle: g.title,
        items: g.items,
        academicYear: _year,
        semester: _sem,
        onDataChanged: () {
          if (mounted) _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _summary['entries'];
    final entryList = entries is List ? entries : const <dynamic>[];

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.55)),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
    );

    InputDecoration filterDecoration(String label) => InputDecoration(
          labelText: label,
          labelStyle: AppTextStyle.inter(fontSize: 13, color: AppColors.notificationSubtitle),
          filled: true,
          fillColor: Colors.white,
          border: fieldBorder,
          enabledBorder: fieldBorder,
          focusedBorder: focusedBorder,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    final grouped = groupScholarshipCatalog(_catalog);
    final byCategory = scholarshipCatalogByCategory(grouped);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppHeader(
              leading: appHeaderNestedBackLeading(context),
              headerTitle: Text('Стипендиальный рейтинг', style: appHeaderNestedTitleStyle),
            ),
            body: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(_year),
                          initialValue: _year,
                          isExpanded: true,
                          decoration: filterDecoration('Учебный год'),
                          items: ['2024-2025', '2025-2026', '2026-2027', '2027-2028']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _year = v);
                            _load();
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey('$_year-$_sem'),
                          initialValue: _sem,
                          isExpanded: true,
                          decoration: filterDecoration('Семестр'),
                          items: const [
                            DropdownMenuItem(value: '1', child: Text('1')),
                            DropdownMenuItem(value: '2', child: Text('2')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _sem = v);
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Утверждено баллов',
                            style: AppTextStyle.inter(fontSize: 12, color: AppColors.notificationSubtitle),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_summary['total_approved'] ?? '—'}',
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Разделы критериев',
                      style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Сначала раскройте категорию (например «1. Учёба»), затем выберите подраздел',
                      style: AppTextStyle.inter(fontSize: 12, color: AppColors.notificationSubtitle, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    for (final block in byCategory)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                              childrenPadding: EdgeInsets.zero,
                              shape: const Border(),
                              collapsedShape: const Border(),
                              iconColor: const Color(0xFF2563EB),
                              collapsedIconColor: AppColors.notificationSubtitle,
                              title: Text(
                                '${block.ordinal}. ${block.categoryLabel}',
                                style: AppTextStyle.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              children: [
                                for (var i = 0; i < block.sections.length; i++) ...[
                                  if (i > 0)
                                    Divider(height: 1, thickness: 1, color: AppColors.lightGrey.withValues(alpha: 0.45)),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _openSection(block.sections[i]),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                block.sections[i].title.isNotEmpty
                                                    ? block.sections[i].title
                                                    : (block.sections[i].ref.isNotEmpty
                                                        ? block.sections[i].ref
                                                        : 'Критерии'),
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyle.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  height: 1.35,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Icon(Icons.chevron_right_rounded,
                                                color: AppColors.chevronRight, size: 24),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Мои заявки',
                      style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    ...entryList.map((raw) {
                      if (raw is! Map) return const SizedBox.shrink();
                      final m = Map<String, dynamic>.from(raw);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
                        ),
                        child: ListTile(
                          title: Text('Заявка #${m['id']}', style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Статус: ${scholarshipRatingEntryStatusRu(m['status'])} · Баллы: ${m['approved_points'] ?? m['suggested_points'] ?? '—'}',
                            style: AppTextStyle.inter(fontSize: 13, color: AppColors.notificationSubtitle),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
