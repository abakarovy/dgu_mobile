import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/student/academic_period.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/dismiss_keyboard_on_tap.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Аргументы для экрана критериев одного раздела (1.1, 1.2, …).
class ScholarshipSectionExtra {
  ScholarshipSectionExtra({
    required this.sectionRef,
    required this.sectionTitle,
    required this.items,
    required this.academicYear,
    required this.semester,
    this.onDataChanged,
  }) : navigationToken = Object();

  final Object navigationToken;
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
  String get _semesterApi =>
      AcademicPeriod(academicYear: widget.extra.academicYear, semester: widget.extra.semester)
          .normalizedSemester;

  Future<String?> _pickConfirmationFilePath() async {
    if (!mounted) return null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Фото из галереи'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Файл (PDF, изображение, DOC…)'),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        );
      },
    );
    if (choice == 'gallery') {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
      return x?.path;
    }
    if (choice == 'file') {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx'],
        withData: false,
      );
      return r?.files.single.path;
    }
    return null;
  }

  Future<({int authors, String? notes})?> _promptCoauthorsIfNeeded(bool divideByCoauthors) async {
    if (!divideByCoauthors) return (authors: 1, notes: null);
    final authorsCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    try {
      final res = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              'Соавторы',
              style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            content: DismissKeyboardOnTap(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text(
                    'Укажите число авторов (включая вас) для корректного деления баллов.',
                    style: AppTextStyle.inter(fontSize: 13, color: AppColors.notificationSubtitle, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: authorsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Число авторов',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий (необязательно)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Далее'),
              ),
            ],
          );
        },
      );
      if (res != true) return null;
      final n = int.tryParse(authorsCtrl.text.trim()) ?? 0;
      if (n < 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Укажите число авторов не меньше 1')),
          );
        }
        return null;
      }
      final notes = notesCtrl.text.trim();
      return (authors: n, notes: notes.isEmpty ? null : notes);
    } finally {
      authorsCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  Future<void> _uploadFor(Map<String, dynamic> card) async {
    final year = widget.extra.academicYear;
    final sem = _semesterApi;
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

    final divide = card['divide_by_coauthors'] == true;
    final co = await _promptCoauthorsIfNeeded(divide);
    if (divide && co == null) return;

    final path = await _pickConfirmationFilePath();
    if (path == null) return;

    try {
      await AppContainer.studentServicesApi.scholarshipUpload(
        academicYear: year,
        semester: sem,
        criterionId: critKey,
        filePath: path,
        filename: path.split(RegExp(r'[\\/]')).last,
        optionKey: optionKey,
        authorsCount: co?.authors,
        notes: co?.notes,
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
    final coauth = c['divide_by_coauthors'] == true;

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
            [
              if (maxP != null) 'До $maxP баллов',
              if (coauth) 'деление на соавторов',
              if (maxP == null && !coauth && desc.isNotEmpty) desc,
            ].where((s) => s.isNotEmpty).join(' · '),
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
    final titleOneLine = e.sectionTitle.isNotEmpty
        ? e.sectionTitle
        : (e.sectionRef.isNotEmpty ? e.sectionRef : 'Критерии');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppHeader(
              leading: appHeaderNestedBackLeading(context),
              headerTitle: Text(
                titleOneLine,
                style: appHeaderNestedTitleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [...e.items.map(_criterionCard)],
            ),
          ),
        ),
      ],
    );
  }
}
