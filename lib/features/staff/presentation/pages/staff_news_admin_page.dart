import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/models/event_model.dart';
import '../../../../shared/widgets/app_header.dart';
import '../widgets/staff_admin_ui.dart';
import '../widgets/staff_web_edit_dialog.dart';

enum StaffNewsEventsTab { news, events }

/// Админка новостей и мероприятий на одном экране.
class StaffNewsAdminPage extends StatefulWidget {
  const StaffNewsAdminPage({
    super.key,
    this.initialTab = StaffNewsEventsTab.news,
    this.showDeleteActions = true,
    this.embeddedInShell = false,
  });

  final StaffNewsEventsTab initialTab;
  final bool showDeleteActions;
  final bool embeddedInShell;

  @override
  State<StaffNewsAdminPage> createState() => _StaffNewsAdminPageState();
}

class _StaffNewsAdminPageState extends State<StaffNewsAdminPage> {
  static const _monthsGenitiveRu = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  late StaffNewsEventsTab _tab;
  List<Map<String, dynamic>> _newsItems = [];
  List<EventModel> _eventItems = [];
  bool _newsLoading = true;
  bool _eventsLoading = true;
  String? _newsError;
  String? _eventsError;

  bool get _isNews => _tab == StaffNewsEventsTab.news;
  String get _appBarTitle => _isNews ? 'Новости' : 'Мероприятия';

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    unawaited(_loadNews());
    unawaited(_loadEvents());
  }

  Future<void> _loadNews() async {
    setState(() {
      _newsLoading = true;
      _newsError = null;
    });
    try {
      final items = await AppContainer.staffModulesApi.getNewsAdminList();
      if (!mounted) return;
      items.sort(_compareNewsBySortOrder);
      setState(() {
        _newsItems = items;
        _newsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _newsLoading = false;
        _newsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _newsLoading = false;
        _newsError = 'Не удалось загрузить новости';
      });
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });
    try {
      final items = await AppContainer.staffModulesApi.getEventsAdminList();
      if (!mounted) return;
      setState(() {
        _eventItems = items;
        _eventsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _eventsLoading = false;
        _eventsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _eventsLoading = false;
        _eventsError = 'Не удалось загрузить мероприятия';
      });
    }
  }

  Future<void> _refreshCurrentTab() async {
    if (_isNews) {
      await _loadNews();
    } else {
      await _loadEvents();
    }
  }

  void _setTab(StaffNewsEventsTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  int _compareNewsBySortOrder(Map<String, dynamic> a, Map<String, dynamic> b) {
    int order(Map<String, dynamic> item) {
      final raw = item['sort_order'];
      if (raw is int) return raw;
      return int.tryParse('$raw') ?? 0;
    }

    return order(a).compareTo(order(b));
  }

  String _formatPublishedDate(dynamic raw) {
    if (raw == null || '$raw'.isEmpty) return '';
    final dt = DateTime.tryParse('$raw')?.toLocal();
    if (dt == null) return '';
    return '${dt.day} ${_monthsGenitiveRu[dt.month - 1]} ${dt.year} г.';
  }

  String _newsMeta(Map<String, dynamic> item) {
    final published = item['is_published'] == true;
    final statusLabel = published ? 'Опубликовано' : 'Черновик';
    final date = _formatPublishedDate(item['created_at'] ?? item['updated_at']);
    return date.isEmpty ? statusLabel : '$statusLabel · $date';
  }

  String _eventMeta(EventModel event) {
    return [
      event.dateRangeLabel,
      if (event.location != null && event.location!.isNotEmpty) event.location,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
  }

  Future<void> _deleteNews(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить новость?'),
        content: Text('«${item['title'] ?? 'Новость'}»'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppContainer.staffModulesApi.deleteNews(
        id is int ? id : int.parse('$id'),
      );
      await _loadNews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteEvent(EventModel event) async {
    final id = event.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить мероприятие?'),
        content: Text(event.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppContainer.staffModulesApi.deleteEvent(id);
      await _loadEvents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openWebEditor({required bool isCreate, int? resourceId}) {
    return showStaffWebEditDialog(
      context: context,
      isNews: _isNews,
      isCreate: isCreate,
      resourceId: resourceId,
    );
  }

  void _showReorderHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Изменение порядка — на сайте college.dgu.ru'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: ListView(
        padding: StaffAdminUi.tabPaddingAll,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _newsEventsSwitch()),
              const SizedBox(width: 10),
              _createIconButton(),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(_tab),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );

    if (widget.embeddedInShell) {
      return ColoredBox(
        color: StaffAdminUi.bg,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: StaffAdminUi.bg,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text(_appBarTitle, style: appHeaderNestedTitleStyle),
        showNotificationIcon: false,
      ),
      body: body,
    );
  }

  Widget _createIconButton() {
    return SizedBox(
      width: StaffAdminUi.pillControlHeight,
      height: StaffAdminUi.pillControlHeight,
      child: FilledButton(
        onPressed: () => _openWebEditor(isCreate: true),
        style: FilledButton.styleFrom(
          backgroundColor: StaffAdminUi.primaryBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Icon(Icons.add, size: 22),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isNews) {
      if (_newsLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (_newsError != null) {
        return Text(
          _newsError!,
          style: AppTextStyle.inter(color: AppColors.grade2Text),
        );
      }
      return _feedSection(
        title: 'Список новостей',
        subtitle:
            'Все публикации и черновики. Порядок сверху вниз — как на сайте; '
            'стрелками можно менять местами.',
        emptyText: 'Новостей пока нет',
        itemCount: _newsItems.length,
        itemBuilder: (index) => _feedRow(
          index: index,
          itemCount: _newsItems.length,
          title: '${_newsItems[index]['title'] ?? 'Новость'}',
          meta: _newsMeta(_newsItems[index]),
          onEdit: () {
            final id = _newsItems[index]['id'];
            final parsed = id is int ? id : int.tryParse('$id');
            unawaited(_openWebEditor(isCreate: false, resourceId: parsed));
          },
          onDelete: widget.showDeleteActions
              ? () => _deleteNews(_newsItems[index])
              : null,
        ),
      );
    }

    if (_eventsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_eventsError != null) {
      return Text(
        _eventsError!,
        style: AppTextStyle.inter(color: AppColors.grade2Text),
      );
    }
    return _feedSection(
      title: 'Список мероприятий',
      subtitle: 'Все мероприятия. Порядок сверху вниз — как на сайте.',
      emptyText: 'Мероприятий пока нет',
      itemCount: _eventItems.length,
      itemBuilder: (index) => _feedRow(
        index: index,
        itemCount: _eventItems.length,
        title: _eventItems[index].title,
        meta: _eventMeta(_eventItems[index]),
        onEdit: () => unawaited(
          _openWebEditor(isCreate: false, resourceId: _eventItems[index].id),
        ),
        onDelete: widget.showDeleteActions
            ? () => _deleteEvent(_eventItems[index])
            : null,
      ),
    );
  }

  Widget _feedSection({
    required String title,
    required String subtitle,
    required String emptyText,
    required int itemCount,
    required Widget Function(int index) itemBuilder,
  }) {
    return StaffAdminUi.sectionCard(
      title: title,
      subtitle: subtitle,
      child: itemCount == 0
          ? Text(emptyText, style: AppTextStyle.inter(color: AppColors.grey))
          : Column(
              children: [
                for (int i = 0; i < itemCount; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  itemBuilder(i),
                ],
              ],
            ),
    );
  }

  Widget _newsEventsSwitch() {
    return Container(
      height: StaffAdminUi.pillControlHeight,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _switchTab(
              label: 'Новости',
              selected: _isNews,
              onTap: () => _setTab(StaffNewsEventsTab.news),
            ),
          ),
          Expanded(
            child: _switchTab(
              label: 'Мероприятия',
              selected: !_isNews,
              onTap: () => _setTab(StaffNewsEventsTab.events),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? StaffAdminUi.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _feedRow({
    required int index,
    required int itemCount,
    required String title,
    required String meta,
    required VoidCallback onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StaffAdminUi.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                '№ ${index + 1}',
                style: AppTextStyle.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 6),
              _orderArrow(
                icon: Icons.keyboard_arrow_up,
                enabled: index > 0,
                onTap: _showReorderHint,
              ),
              const SizedBox(height: 4),
              _orderArrow(
                icon: Icons.keyboard_arrow_down,
                enabled: index < itemCount - 1,
                onTap: _showReorderHint,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    style: AppTextStyle.inter(
                      fontSize: 12,
                      color: AppColors.grey,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _actionButtons(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons({
    required VoidCallback onEdit,
    VoidCallback? onDelete,
  }) {
    const height = 36.0;
    const color = Color(0xFFDC2626);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: StaffAdminUi.cardBorder),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: AppTextStyle.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              child: const Text('Ред.'),
            ),
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: height,
              child: OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.25)),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Удалить'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _orderArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? Colors.white : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: StaffAdminUi.cardBorder),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? AppColors.textPrimary
                : AppColors.grey.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
