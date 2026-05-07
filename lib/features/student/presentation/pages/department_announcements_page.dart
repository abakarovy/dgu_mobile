import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/student/department_announcement_prompt.dart';
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
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AppContainer.studentServicesApi.departmentAnnouncementsMy();
      if (mounted) setState(() => _items = list);
      unawaited(DepartmentAnnouncementPrompt.acknowledgeCurrentList(list));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd.MM.yyyy HH:mm').format(d.toLocal());
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
      headerTitle: Text('Объявления отделения', style: appHeaderNestedTitleStyle),
            ),
            body: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(_error!, style: AppTextStyle.inter(color: Colors.red, fontSize: 13)),
                      ),
                    ),
                  if (_loading && _items.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Объявлений пока нет. Пустой ответ при нормальной сети возможен, '
                            'если группа не сопоставлена — обратитесь в деканат.',
                            textAlign: TextAlign.center,
                            style: AppTextStyle.inter(
                              color: AppColors.notificationSubtitle,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final m = _items[index];
                            final title = '${m['title'] ?? 'Объявление'}';
                            final body = '${m['body'] ?? ''}';
                            final code = '${m['group_code'] ?? ''}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
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
                              ),
                            );
                          },
                          childCount: _items.length,
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
}
