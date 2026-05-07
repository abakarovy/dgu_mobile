import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Аргументы для экрана критериев одного раздела (1.1, 1.2, …).
class ScholarshipSectionExtra {
  const ScholarshipSectionExtra({
    required this.sectionRef,
    required this.sectionTitle,
    required this.items,
    required this.academicYear,
    required this.semester,
    this.onDataChanged,
  });

  final String sectionRef;
  final String sectionTitle;
  final List<Map<String, dynamic>> items;
  final String academicYear;
  final String semester;
  final VoidCallback? onDataChanged;
}

/// Список критериев выбранного раздела каталога.
class ScholarshipSectionPage extends StatefulWidget {
  const ScholarshipSectionPage({super.key, required this.extra});

  final ScholarshipSectionExtra extra;

  @override
  State<ScholarshipSectionPage> createState() => _ScholarshipSectionPageState();
}

class _ScholarshipSectionPageState extends State<ScholarshipSectionPage> {
  Future<void> _uploadFor(Map<String, dynamic> card) async {
    final year = widget.extra.academicYear;
    final sem = widget.extra.semester;
    final critKey = '${card['criterion_ref'] ?? card['id'] ?? ''}'.trim();
    if (critKey.isEmpty) return;

    String? optionKey;
    final opts = card['options'];
    if (opts is List && opts.isNotEmpty) {
      if (!mounted) return;
      optionKey = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              'Вариант критерия',
              style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final o in opts)
                    if (o is Map)
                      ListTile(
                        title: Text('${o['label'] ?? o['key'] ?? ''}'),
                        subtitle: o['points'] != null ? Text('До ${o['points']} б.') : null,
                        onTap: () => Navigator.pop(ctx, '${o['key']}'.trim()),
                      ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ],
          );
        },
      );
      if (optionKey == null || optionKey.isEmpty) return;
    }

    final pick = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pick == null) return;
    try {
      await AppContainer.studentServicesApi.scholarshipUpload(
        academicYear: year,
        semester: sem,
        criterionId: critKey,
        filePath: pick.path,
        filename: pick.name,
        optionKey: optionKey,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заявка отправлена')));
        widget.extra.onDataChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Widget _criterionCard(Map<String, dynamic> c) {
    final canUpload = c['allow_upload'] == true;
    final critKey = '${c['criterion_ref'] ?? c['id'] ?? ''}'.trim();
    final title = '${c['title'] ?? 'Критерий'}';
    final desc = '${c['description'] ?? ''}';
    final maxP = c['max_points'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          iconColor: const Color(0xFFCA8A04),
          collapsedIconColor: AppColors.notificationSubtitle,
          title: Text(title, style: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 15)),
          subtitle: Text(
            maxP != null ? 'До $maxP баллов' : (desc.isNotEmpty ? desc : ' '),
            style: AppTextStyle.inter(fontSize: 12, color: AppColors.notificationSubtitle),
          ),
          children: [
            if (desc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  desc,
                  style: AppTextStyle.inter(fontSize: 14, height: 1.35, color: AppColors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: !canUpload || critKey.isEmpty ? null : () => _uploadFor(c),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Прикрепить подтверждение'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.extra;
    final header = e.sectionRef.isNotEmpty ? e.sectionRef : 'Критерии';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppHeader(
              leading: appHeaderNestedBackLeading(context),
              headerTitle: Text(header, style: appHeaderNestedTitleStyle),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (e.sectionTitle.isNotEmpty) ...[
                  Text(
                    e.sectionTitle,
                    style: AppTextStyle.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.notificationSubtitle,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...e.items.map(_criterionCard),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
