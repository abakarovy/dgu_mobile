import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/student/department_announcement_prompt.dart';
import 'package:dgu_mobile/core/student/student_attestation.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class DepartmentAnnouncementsPage extends StatefulWidget {
  const DepartmentAnnouncementsPage({super.key});

  @override
  State<DepartmentAnnouncementsPage> createState() => _DepartmentAnnouncementsPageState();
}

class _DepartmentAnnouncementsPageState extends State<DepartmentAnnouncementsPage> {
  bool _loading = true;
  String? _errorDept;
  String? _errorHints;
  List<Map<String, dynamic>> _deptItems = const [];
  List<RetakeHint> _retakeHints = const [];
  bool _archive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorDept = null;
      _errorHints = null;
    });
    try {
      final dept =
          await AppContainer.studentServicesApi.departmentAnnouncementsMy(archive: _archive);
      if (mounted) setState(() => _deptItems = dept);
      if (!_archive) {
        unawaited(DepartmentAnnouncementPrompt.acknowledgeCurrentList(dept));
      }
    } catch (e) {
      if (mounted) setState(() => _errorDept = '$e');
    }

    try {
      final bundle = await AppContainer.gradesApi.loadMyGrades();
      final hints = buildDepartmentRetakeHints(bundle.grades);
      if (mounted) setState(() => _retakeHints = hints);
    } catch (e) {
      if (mounted) setState(() => _errorHints = '$e');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setArchive(bool v) async {
    if (_archive == v) return;
    setState(() => _archive = v);
    await _load();
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final win = getAttestationWindow(DateTime.now());
    final winFmt =
        '${DateFormat('dd.MM.yyyy').format(win.start)} — ${DateFormat('dd.MM.yyyy').format(win.end)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppHeader(
              leading: appHeaderNestedBackLeading(context),
              headerTitle: Text('Объявления', style: appHeaderNestedTitleStyle),
            ),
            body: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Актуальные'),
                            selected: !_archive,
                            onSelected: (_) => _setArchive(false),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Архив'),
                            selected: _archive,
                            onSelected: (_) => _setArchive(true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorDept != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          _errorDept!,
                          style: AppTextStyle.inter(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Сообщение отделения',
                        style: AppTextStyle.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (_loading && _deptItems.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_deptItems.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _archive
                              ? 'В архиве объявлений нет.'
                              : 'Объявлений отделения пока нет. Пустой ответ при нормальной сети возможен, '
                                  'если группа не сопоставлена — обратитесь в деканат.',
                          style: AppTextStyle.inter(
                            color: AppColors.notificationSubtitle,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final m = _deptItems[index];
                            final title = '${m['title'] ?? 'Объявление'}';
                            final body = '${m['body'] ?? ''}';
                            final code = '${m['group_code'] ?? ''}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _deptCard(title, body, code, m),
                            );
                          },
                          childCount: _deptItems.length,
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Пересдачи и итоги аттестации',
                            style: AppTextStyle.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Период журнала: $winFmt. Показаны только зачёт и экзамен с неудовлетворительной оценкой.',
                            style: AppTextStyle.inter(
                              fontSize: 12,
                              height: 1.35,
                              color: AppColors.notificationSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorHints != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          _errorHints!,
                          style: AppTextStyle.inter(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ),
                  if (!_loading && _retakeHints.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                          'Нет зачётов или экзаменов с неудовлетворительной оценкой в этом окне аттестации.',
                          style: AppTextStyle.inter(
                            color: AppColors.notificationSubtitle,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final h = _retakeHints[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.subjectName,
                                      style: AppTextStyle.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.notificationSubtitle,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      h.detailText,
                                      style: AppTextStyle.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        height: 1.25,
                                        color: const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _retakeHints.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deptCard(String title, String body, String code, Map<String, dynamic> m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (code.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                _fmt(m['created_at']?.toString()),
                style: AppTextStyle.inter(
                  fontSize: 11,
                  color: AppColors.notificationSubtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTextStyle.inter(
                fontSize: 14,
                height: 1.35,
                color: AppColors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
