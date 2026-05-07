import 'package:dgu_mobile/core/constants/api_constants.dart';
import 'package:dgu_mobile/core/constants/app_colors.dart';
import 'package:dgu_mobile/core/di/app_container.dart';
import 'package:dgu_mobile/core/theme/app_text_styles.dart';
import 'package:dgu_mobile/shared/widgets/app_header.dart';
import 'package:dgu_mobile/shared/widgets/network_degraded_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  double _points = 0;
  Map<String, dynamic> _complete = {};
  bool _shareBusy = false;
  Map<String, dynamic>? _shareInfo;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
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
                    await SharePlus.instance.share(ShareParams(text: url));
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

  Future<void> _pickAndUpload() async {
    final pick = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (pick == null) return;
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
        filePath: pick.path,
        filename: pick.name,
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
              headerTitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Портфолио', style: appHeaderNestedTitleStyle),
                  Text(
                    'Баллы: ${_points.toStringAsFixed(1)}',
                    style: AppTextStyle.inter(fontSize: 11, color: AppColors.notificationSubtitle),
                  ),
                ],
              ),
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
              icon: const Icon(Icons.add_photo_alternate_outlined),
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
                    tabs: const [
                      Tab(text: 'Мои файлы'),
                      Tab(text: 'Официальные'),
                    ],
                  ),
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
    final st = '${m['status'] ?? 'pending'}';
    final id = m['id'];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        title: Text(title, style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
        subtitle: Text('${m['section'] ?? ''} · $st', style: AppTextStyle.inter(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(st).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                st,
                style: AppTextStyle.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(st)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => _openFileUrl(m['file_url']?.toString()),
            ),
            if (st == 'pending' && id is int)
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
    final title = '${m['title'] ?? 'Документ'}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.picture_as_pdf_outlined, size: 20)),
        title: Text(title, style: AppTextStyle.inter(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openFileUrl(m['file_url']?.toString()),
      ),
    );
  }
}
