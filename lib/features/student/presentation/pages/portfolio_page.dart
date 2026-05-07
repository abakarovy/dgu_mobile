import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/realtime/student_modules_refresh.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Раздел загрузки (`section`) из API — подпись для списка.
String portfolioSectionLabelRu(Object? raw) {
  switch ('${raw ?? ''}'.trim().toLowerCase()) {
    case 'general':
      return 'Прочее';
    case 'certificate':
      return 'Сертификаты';
    case 'diploma':
      return 'Дипломы и грамоты';
    case 'course':
      return 'Курсы';
    default:
      final s = '${raw ?? ''}'.trim();
      return s.isEmpty ? 'Раздел' : s;
  }
}

/// Статус модерации самозагрузки.
String portfolioUploadStatusRu(Object? raw) {
  switch ('${raw ?? ''}'.trim().toLowerCase()) {
    case 'pending':
      return 'На проверке';
    case 'approved':
      return 'Одобрено';
    case 'rejected':
      return 'Отклонено';
    default:
      final s = '${raw ?? ''}'.trim();
      return s.isEmpty ? '—' : s;
  }
}

bool _isPortfolioImageRef(String? ref, [String? fileName]) {
  bool ext(String? s) {
    if (s == null || s.isEmpty) return false;
    final q = s.toLowerCase().split('?').first;
    return q.endsWith('.jpg') ||
        q.endsWith('.jpeg') ||
        q.endsWith('.png') ||
        q.endsWith('.gif') ||
        q.endsWith('.webp');
  }

  return ext(ref) || ext(fileName);
}

String _portfolioImageExtension(String? fileName, String url) {
  String fromPath(String? s) {
    if (s == null || s.isEmpty) return '';
    final base = s.toLowerCase().split('?').first.split('/').last;
    final dot = base.lastIndexOf('.');
    if (dot <= 0 || dot == base.length - 1) return '';
    return base.substring(dot + 1);
  }

  var e = fromPath(fileName);
  if (e.isEmpty) e = fromPath(url);
  e = e.toLowerCase();
  if (e == 'jpg') return 'jpeg';
  if (e == 'jpeg' || e == 'png' || e == 'gif' || e == 'webp') return e;
  return 'png';
}

MimeType _mimeForImageExt(String ext) {
  switch (ext) {
    case 'jpeg':
    case 'jpg':
      return MimeType.jpeg;
    case 'gif':
      return MimeType.gif;
    case 'webp':
      return MimeType.webp;
    case 'png':
    default:
      return MimeType.png;
  }
}

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late final VoidCallback _portfolioWsListener;
  bool _loading = true;
  int _points = 0;
  Map<String, dynamic> _complete = {};
  bool _shareBusy = false;
  Map<String, dynamic>? _shareInfo;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _portfolioWsListener = () {
      if (mounted) _load();
    };
    StudentModulesRefreshBus.portfolioTick.addListener(_portfolioWsListener);
    _load();
  }

  @override
  void dispose() {
    StudentModulesRefreshBus.portfolioTick.removeListener(_portfolioWsListener);
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rating = await AppContainer.studentServicesApi.portfolioRatingTotal();
      final full = await AppContainer.studentServicesApi.portfolioMyComplete();
      Map<String, dynamic>? share;
      try {
        final s = await AppContainer.studentServicesApi.portfolioShareStatus();
        if (s != null) share = s;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _points = rating;
          _complete = full;
          if (share != null) _shareInfo = share;
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _publicUrlFrom(Map<String, dynamic>? m) {
    if (m == null) return null;
    final u = m['public_url'] ?? m['url'];
    final s = u?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  Future<void> _showPublicLinkSheet(String url) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Публичная ссылка',
                  style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'По ссылке открывается публичная версия портфолио — поделитесь ею или скопируйте.',
                  style: AppTextStyle.inter(fontSize: 13, color: AppColors.notificationSubtitle, height: 1.35),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(url, style: AppTextStyle.inter(fontSize: 13, height: 1.35)),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ссылка скопирована')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Копировать'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Share.share(url);
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Поделиться…'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final parsed = Uri.tryParse(url);
                    if (parsed != null && await canLaunchUrl(parsed)) {
                      await launchUrl(parsed, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Открыть в браузере'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await _regenerateShare();
                  },
                  child: const Text('Сгенерировать новую ссылку'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    await _disableShareWithConfirm();
                  },
                  child: Text(
                    'Отключить публичный просмотр',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSharePressed() async {
    final existing = _publicUrlFrom(_shareInfo);
    if (existing != null) {
      await _showPublicLinkSheet(existing);
      return;
    }
    await _enableShare();
  }

  Color _statusColor(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'approved':
        return AppColors.primaryGreen;
      case 'rejected':
        return AppColors.grade2Text;
      default:
        return AppColors.grade4Text;
    }
  }

  String _workTypeLabelRu(String? code) {
    switch ((code ?? '').trim()) {
      case 'coursework':
        return 'Курсовая работа';
      case 'diploma':
        return 'Дипломная работа';
      case 'individual_project':
        return 'Индивидуальный проект';
      default:
        return code?.trim().isNotEmpty == true ? code! : 'Итоговая работа';
    }
  }

  String? _fileRefFrom(Map<String, dynamic> m) {
    final u = m['file_url']?.toString().trim();
    if (u != null && u.isNotEmpty) return u;
    final p = m['file_path']?.toString().trim();
    if (p != null && p.isNotEmpty) return p;
    return null;
  }

  Future<void> _pickAndUpload() async {
    if (!mounted) return;
    final source = await showModalBottomSheet<String>(
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
                title: const Text('Файл (PDF, DOC, изображение…)'),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    String? path;
    String? filename;
    if (source == 'gallery') {
      final pick = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
      path = pick?.path;
      filename = pick?.name;
    } else if (source == 'file') {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx'],
        withData: false,
      );
      path = r?.files.single.path;
      filename = r?.files.single.name;
    }
    if (path == null) return;
    if (!mounted) return;

    final section = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Раздел портфолио',
          style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Прочее', style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(c, 'general'),
            ),
            ListTile(
              title: Text('Сертификаты', style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(c, 'certificate'),
            ),
            ListTile(
              title: Text('Дипломы и грамоты', style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(c, 'diploma'),
            ),
            ListTile(
              title: Text('Курсы', style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(c, 'course'),
            ),
          ],
        ),
      ),
    );
    if (section == null) return;
    try {
      await AppContainer.studentServicesApi.portfolioUpload(
        filePath: path,
        filename: filename,
        section: section,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Файл отправлен')));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _openFileUrl(String? rel) async {
    if (rel == null || rel.isEmpty) return;
    final u = Uri.parse(ApiConstants.resolvePublicFileUrl(rel));
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveImageFromPublicUrl(String url, {String? fileName}) async {
    try {
      final dio = Dio();
      final res = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final raw = res.data;
      if (raw == null || raw.isEmpty) {
        throw StateError('Пустой ответ');
      }
      final bytes = Uint8List.fromList(raw);
      final ext = _portfolioImageExtension(fileName, url);
      final mime = _mimeForImageExt(ext);
      var base = (fileName ?? 'portfolio_image').trim();
      if (base.toLowerCase().endsWith('.$ext')) {
        base = base.substring(0, base.length - ext.length - 1);
      } else if (base.contains('.')) {
        base = base.split('.').first;
      }
      if (base.isEmpty) base = 'portfolio_image';
      try {
        await FileSaver.instance.saveAs(
          name: base,
          bytes: bytes,
          fileExtension: ext,
          mimeType: mime,
        );
      } on UnimplementedError {
        await FileSaver.instance.saveFile(
          name: base,
          bytes: bytes,
          fileExtension: ext,
          mimeType: mime,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл сохранён')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $e')),
      );
    }
  }

  Future<void> _openSelfItemPreview(String? ref, {String? fileName}) async {
    if (ref == null || ref.isEmpty) return;
    if (!_isPortfolioImageRef(ref, fileName)) {
      await _openFileUrl(ref);
      return;
    }
    if (!mounted) return;
    final url = ApiConstants.resolvePublicFileUrl(ref);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height * 0.85;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                SizedBox(
                  width: double.maxFinite,
                  height: h,
                  child: ColoredBox(
                    color: Colors.black,
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Center(
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(color: Colors.white),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Не удалось показать изображение',
                              textAlign: TextAlign.center,
                              style: AppTextStyle.inter(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          icon: const Icon(Icons.download_rounded, color: Colors.white),
                          tooltip: 'Сохранить изображение',
                          onPressed: () => _saveImageFromPublicUrl(url, fileName: fileName),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          icon: const Icon(Icons.share_rounded, color: Colors.white),
                          tooltip: 'Поделиться ссылкой',
                          onPressed: () async {
                            await Share.share(url, subject: fileName ?? 'Портфолио');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deletePending(int id) async {
    try {
      await AppContainer.studentServicesApi.portfolioDeletePending(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Удалено')));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _enableShare() async {
    setState(() => _shareBusy = true);
    try {
      final res = await AppContainer.studentServicesApi.portfolioShareEnable();
      if (!mounted) return;
      setState(() => _shareInfo = {...?_shareInfo, ...res});
      final url = _publicUrlFrom(res) ?? _publicUrlFrom(_shareInfo);
      if (url != null) {
        await _showPublicLinkSheet(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ссылка не пришла в ответе сервера')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _shareBusy = false);
    }
  }

  Future<void> _regenerateShare() async {
    setState(() => _shareBusy = true);
    try {
      final res = await AppContainer.studentServicesApi.portfolioShareRegenerate();
      if (!mounted) return;
      setState(() => _shareInfo = {...?_shareInfo, ...res});
      final url = _publicUrlFrom(res) ?? _publicUrlFrom(_shareInfo);
      if (url != null) {
        await _showPublicLinkSheet(url);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('В ответе нет публичного URL — обновите экран')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _shareBusy = false);
    }
  }

  Future<void> _disableShareWithConfirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Отключить публичный доступ?',
          style: AppTextStyle.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
        ),
        content: Text(
          'Текущая ссылка на портфолио перестанет открываться.',
          style: AppTextStyle.inter(fontSize: 14, color: AppColors.grey, height: 1.35),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Отключить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _shareBusy = true);
    try {
      await AppContainer.studentServicesApi.portfolioShareDisable();
      if (!mounted) return;
      setState(() => _shareInfo = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Публичный доступ отключён')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _shareBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final self = _complete['self_uploads'];
    final selfList = self is List ? self.cast<dynamic>() : const <dynamic>[];
    final official = _complete['official_final_works'];
    final offList = official is List ? official.cast<dynamic>() : const <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NetworkDegradedBanner(),
        Expanded(
          child: Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppHeader(
              leading: appHeaderNestedBackLeading(context),
              headerTitle: Text('Портфолио', style: appHeaderNestedTitleStyle),
              actions: [
                if (_shareBusy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(
                    onPressed: _onSharePressed,
                    tooltip: _publicUrlFrom(_shareInfo) != null ? 'Ссылка на портфолио' : 'Включить публичную ссылку',
                    icon: const Icon(Icons.link_rounded, color: AppColors.textPrimary),
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _pickAndUpload,
              backgroundColor: const Color(0xFF0891B2),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Загрузить'),
            ),
            body: Column(
              children: [
                Material(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tab,
                    labelColor: const Color(0xFF0891B2),
                    unselectedLabelColor: AppColors.notificationSubtitle,
                    labelStyle: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: AppTextStyle.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    indicatorColor: const Color(0xFF0891B2),
                    tabs: const [
                      Tab(text: 'Мои файлы'),
                      Tab(text: 'Официальные'),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _tab.index == 0
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Баллы портфолио: $_points (одобренные самозагрузки)',
                                textAlign: TextAlign.center,
                                style: AppTextStyle.inter(
                                  fontSize: 12,
                                  height: 1.25,
                                  color: AppColors.notificationSubtitle,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Не стипендиальный рейтинг',
                                textAlign: TextAlign.center,
                                style: AppTextStyle.inter(fontSize: 11, color: AppColors.grey, height: 1.2),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: _loading && selfList.isEmpty && offList.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tab,
                          children: [
                            RefreshIndicator(
                              onRefresh: _load,
                              child: selfList.isEmpty && !_loading
                                  ? ListView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      children: [
                                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
                                        Center(
                                          child: Text(
                                            'Нет загрузок',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyle.inter(color: AppColors.notificationSubtitle, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView(
                                      padding: const EdgeInsets.all(16),
                                      children: [
                                        for (final raw in selfList)
                                          if (raw is Map) _tileSelf(Map<String, dynamic>.from(raw)),
                                      ],
                                    ),
                            ),
                            RefreshIndicator(
                              onRefresh: _load,
                              child: offList.isEmpty && !_loading
                                  ? ListView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      children: [
                                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
                                        Center(
                                          child: Text(
                                            'Нет документов отделения',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyle.inter(color: AppColors.notificationSubtitle, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView(
                                      padding: const EdgeInsets.all(16),
                                      children: [
                                        for (final raw in offList)
                                          if (raw is Map) _tileOfficial(Map<String, dynamic>.from(raw)),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tileSelf(Map<String, dynamic> m) {
    final title = '${m['file_name'] ?? m['description'] ?? 'Файл'}';
    final statusRaw = '${m['status'] ?? 'pending'}'.trim().toLowerCase();
    final stLabel = portfolioUploadStatusRu(m['status']);
    final secLabel = portfolioSectionLabelRu(m['section']);
    final rawId = m['id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId');
    final ref = _fileRefFrom(m);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        onTap: () => _openSelfItemPreview(ref, fileName: m['file_name']?.toString()),
        title: Text(title, style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$secLabel · $stLabel',
          style: AppTextStyle.inter(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(statusRaw).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                stLabel,
                style: AppTextStyle.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(statusRaw),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              tooltip: 'Открыть во внешнем приложении',
              onPressed: () => _openFileUrl(ref),
            ),
            if (statusRaw == 'pending' && id != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deletePending(id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tileOfficial(Map<String, dynamic> m) {
    final subject = '${m['subject_name'] ?? ''}'.trim();
    final wt = _workTypeLabelRu(m['work_type']?.toString());
    final title = subject.isNotEmpty ? subject : (m['original_filename'] ?? m['title'] ?? 'Документ').toString();
    final deadline = m['upload_deadline_at']?.toString();
    final past = m['is_past_deadline'] == true;
    final ref = _fileRefFrom(m);
    final subtitle = StringBuffer(wt);
    if (deadline != null && deadline.isNotEmpty) {
      subtitle.write(' · дедлайн: $deadline');
    }
    if (past) subtitle.write(' · просрочено');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0891B2).withValues(alpha: 0.12),
          child: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFF0891B2)),
        ),
        title: Text(title, style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle.toString(),
          style: AppTextStyle.inter(fontSize: 12, color: past ? AppColors.grade2Text : AppColors.notificationSubtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openFileUrl(ref),
      ),
    );
  }
}
