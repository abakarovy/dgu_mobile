import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/teacher_shell_scaffold.dart';

/// Журнал преподавателя: `GET /api/journal/subjects/my`.
class TeacherJournalPage extends StatefulWidget {
  const TeacherJournalPage({
    super.key,
    this.embeddedInShell = true,
  });

  final bool embeddedInShell;

  @override
  State<TeacherJournalPage> createState() => _TeacherJournalPageState();
}

class _TeacherJournalPageState extends State<TeacherJournalPage> {
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await AppContainer.staffModulesApi.getJournalSubjectsMy();
      if (!mounted) return;
      setState(() {
        _subjects = items;
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
        _error = 'Не удалось загрузить предметы';
      });
    }
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: AppUi.screenPaddingAll,
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _subjects.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppUi.screenPaddingAll,
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    'Нет предметов',
                    style: AppTextStyle.inter(color: AppColors.grey),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppUi.screenPaddingAll,
              itemCount: _subjects.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppUi.spacingS),
              itemBuilder: (context, index) {
                final s = _subjects[index];
                final name = (s['name'] ?? s['title'] ?? s['subject_name'] ?? 'Предмет')
                    .toString();
                final group = (s['group_code'] ?? s['group'] ?? '').toString();
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppUi.radiusL),
                  child: ListTile(
                    title: Text(
                      name,
                      style: AppTextStyle.inter(fontWeight: FontWeight.w700),
                    ),
                    subtitle: group.isNotEmpty ? Text(group) : null,
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) {
      return TeacherShellScaffold(child: _body());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Журнал', style: appHeaderNestedTitleStyle),
        showNotificationIcon: false,
      ),
      body: _body(),
    );
  }
}
