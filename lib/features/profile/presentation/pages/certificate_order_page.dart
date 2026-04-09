import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';

class CertificateOrderPage extends StatefulWidget {
  const CertificateOrderPage({super.key});

  @override
  State<CertificateOrderPage> createState() => _CertificateOrderPageState();
}

class _CertificateOrderPageState extends State<CertificateOrderPage> {
  static const _prefsKey = 'profile:certificate_orders_v2';

  static const List<String> _types = [
    'Об обучении',
    'Архивная справка',
    'О стипендии',
    'Об оплате',
    'Вызов(по месту требования)',
  ];

  static const List<String> _formats = [
    'Бумажная',
    'Электронная',
    'С электронной подписью',
  ];

  final _whereCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  String? _type;
  String? _format;
  bool _busy = false;

  List<_CertOrder> _history = const [];
  String? _selectedOrderNumber;
  String _filterType = 'Все справки';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _whereCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? <String>[];
      final list = <_CertOrder>[];
      for (final s in raw) {
        try {
          final j = jsonDecode(s);
          if (j is Map<String, dynamic>) list.add(_CertOrder.fromJson(j));
        } catch (_) {}
      }
      list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
      if (!mounted) return;
      setState(() {
        _history = list;
        _selectedOrderNumber ??= list.isEmpty ? null : list.first.orderNumber;
      });
    } catch (_) {}
  }

  Future<void> _saveHistory(List<_CertOrder> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, [for (final o in list) jsonEncode(o.toJson())]);
    } catch (_) {}
  }

  String _newOrderNumber() {
    final now = DateTime.now();
    // Достаточно читабельно и уникально для мок-истории.
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _createOrder() async {
    if (_busy) return;
    final type = (_type ?? '').trim();
    final format = (_format ?? '').trim();
    final where = _whereCtrl.text.trim();
    final comment = _commentCtrl.text.trim();

    if (type.isEmpty || format.isEmpty || where.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните тип, формат и “Куда предоставляется”')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final orderNo = _newOrderNumber();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final created = _CertOrder(
        orderNumber: orderNo,
        type: type,
        format: format,
        where: where,
        comment: comment.isEmpty ? null : comment,
        status: _CertOrderStatus.inWork,
        createdAtMs: nowMs,
      );
      final next = [created, ..._history];
      setState(() {
        _history = next;
        _selectedOrderNumber = created.orderNumber;
      });
      await _saveHistory(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заказ создан: № $orderNo')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  _CertOrder? get _currentOrder {
    final sel = (_selectedOrderNumber ?? '').trim();
    if (sel.isNotEmpty) {
      for (final o in _history) {
        if (o.orderNumber == sel) return o;
      }
    }
    return _history.isEmpty ? null : _history.first;
  }

  Future<void> _checkStatus() async {
    if (_busy) return;
    final o = _currentOrder;
    if (o == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('История пустая')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final nextStatus = switch (o.status) {
        _CertOrderStatus.inWork => _CertOrderStatus.ready,
        _CertOrderStatus.ready => _CertOrderStatus.ready,
        _CertOrderStatus.downloaded => _CertOrderStatus.downloaded,
      };
      final updated = o.copyWith(status: nextStatus);
      final next = [updated, ..._history.skip(1)];
      setState(() => _history = next);
      await _saveHistory(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Статус: ${updated.statusLabel}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_busy) return;
    final o = _currentOrder;
    if (o == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('История пустая')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = o.copyWith(status: _CertOrderStatus.downloaded);
      final next = [updated, ..._history.skip(1)];
      setState(() => _history = next);
      await _saveHistory(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF скачан')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  TextStyle get _labelStyle => AppTextStyle.inter(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        height: 1.2,
        color: const Color(0xFF000000),
      );

  TextStyle get _fieldStyle => AppTextStyle.inter(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        height: 1.2,
        color: const Color(0xFF000000),
      );

  InputDecoration _decoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _fieldStyle.copyWith(color: const Color(0x4D000000)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF000000), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF000000), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF000000), width: 1.5),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // DropdownButtonFormField имеет свою внутреннюю разметку/высоту, из-за чего визуально
    // отличается от обычного TextField. Здесь используем InputDecorator + popup menu,
    // чтобы размеры/рамка были 1-в-1 как у текстовых полей.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _busy
                ? null
                : () async {
                    final box = context.findRenderObject() as RenderBox?;
                    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
                    if (box == null || overlay == null) return;
                    final pos = RelativeRect.fromRect(
                      Rect.fromPoints(
                        box.localToGlobal(Offset.zero, ancestor: overlay),
                        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
                      ),
                      Offset.zero & overlay.size,
                    );
                    final selected = await showMenu<String>(
                      context: context,
                      position: pos,
                      items: [
                        for (final it in items)
                          PopupMenuItem<String>(
                            value: it,
                            child: Text(it, style: _fieldStyle),
                          ),
                      ],
                    );
                    if (selected != null) onChanged(selected);
                  },
            child: InputDecorator(
              decoration: _decoration(hint: ''),
              isEmpty: (value == null || value.trim().isEmpty),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (value == null || value.trim().isEmpty) ? '' : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _fieldStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF000000)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    final height = maxLines == 1 ? 44.0 : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 44,
            maxHeight: maxLines == 1 ? 44 : 44 * maxLines.toDouble(),
          ),
          child: SizedBox(
            height: height,
            child: TextField(
              controller: controller,
              enabled: !_busy,
              maxLines: maxLines,
              keyboardType: maxLines == 1 ? TextInputType.text : TextInputType.multiline,
              style: _fieldStyle,
              decoration: _decoration(hint: hint).copyWith(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: maxLines == 1 ? 14 : 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 35,
      child: ElevatedButton(
        onPressed: _busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E63D5),
          disabledBackgroundColor: const Color(0xFF2E63D5).withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _secondaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 35,
      child: OutlinedButton(
        onPressed: _busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2E63D5), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1.0,
            color: const Color(0xFF2E63D5),
          ),
        ),
      ),
    );
  }

  Widget _filterDropdown() {
    final items = <String>['Все справки', ..._types];
    return _dropdown(
      label: 'Фильтр справок',
      value: _filterType,
      items: items,
      onChanged: (v) {
        final next = (v ?? '').trim();
        if (next.isEmpty) return;
        setState(() => _filterType = next);
      },
    );
  }

  List<_CertOrder> get _filteredHistory {
    if (_filterType == 'Все справки') return _history;
    return _history.where((e) => e.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cur = _currentOrder;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        headerTitle: Text(
          'Заказать справку',
          style: AppTextStyle.inter(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            height: 1.2,
            color: const Color(0xFF000000),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF000000)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dropdown(
                label: 'Тип справки',
                value: _type,
                items: _types,
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 12),
              _dropdown(
                label: 'Формат',
                value: _format,
                items: _formats,
                onChanged: (v) => setState(() => _format = v),
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Куда предоставляется',
                controller: _whereCtrl,
                hint: 'Например по месту работы',
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Комментарий (необязательно)',
                controller: _commentCtrl,
                hint: '',
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              Text(
                'Номер заказа: ${cur?.orderNumber ?? '—'}',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 12),
              _primaryButton(text: 'Создать заказ в 1С', onTap: _createOrder),
              const SizedBox(height: 10),
              _secondaryButton(text: 'Проверить статус', onTap: _checkStatus),
              const SizedBox(height: 10),
              _secondaryButton(text: 'Скачать PDF', onTap: _downloadPdf),
              const SizedBox(height: 18),
              Text(
                'История справок',
                style: AppTextStyle.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.2,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 10),
              _filterDropdown(),
              const SizedBox(height: 12),
              if (_filteredHistory.isEmpty)
                Text(
                  'Пока нет заказов',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.2,
                    color: const Color(0x4D000000),
                  ),
                )
              else
                Column(
                  children: [
                    for (final o in _filteredHistory)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _historyTile(o),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyTile(_CertOrder o) {
    final dt = DateTime.fromMillisecondsSinceEpoch(o.createdAtMs);
    final dd = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final tt = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final selected = _selectedOrderNumber == o.orderNumber;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedOrderNumber = o.orderNumber;
          _type = o.type;
          _format = o.format;
          _whereCtrl.text = o.where;
          _commentCtrl.text = (o.comment ?? '');
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0x0F2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0x24000000),
            width: selected ? 1 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    o.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.1,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$dd $tt',
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    height: 1.0,
                    color: const Color(0x80000000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Номер заказа: ${o.orderNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1.0,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  o.format,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    height: 1.0,
                    color: const Color(0xFF2E63D5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  o.statusLabel,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    height: 1.0,
                    color: o.status == _CertOrderStatus.downloaded
                        ? const Color(0xFF16A34A)
                        : (o.status == _CertOrderStatus.ready
                            ? const Color(0xFF2E63D5)
                            : const Color(0xFF000000)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _CertOrderStatus { inWork, ready, downloaded }

class _CertOrder {
  const _CertOrder({
    required this.orderNumber,
    required this.type,
    required this.format,
    required this.where,
    required this.comment,
    required this.status,
    required this.createdAtMs,
  });

  final String orderNumber;
  final String type;
  final String format;
  final String where;
  final String? comment;
  final _CertOrderStatus status;
  final int createdAtMs;

  String get statusLabel => switch (status) {
        _CertOrderStatus.inWork => 'В работе',
        _CertOrderStatus.ready => 'Готово',
        _CertOrderStatus.downloaded => 'Скачано',
      };

  _CertOrder copyWith({
    _CertOrderStatus? status,
  }) {
    return _CertOrder(
      orderNumber: orderNumber,
      type: type,
      format: format,
      where: where,
      comment: comment,
      status: status ?? this.status,
      createdAtMs: createdAtMs,
    );
  }

  factory _CertOrder.fromJson(Map<String, dynamic> j) {
    final st = (j['status'] ?? '').toString();
    final parsed = switch (st) {
      'ready' => _CertOrderStatus.ready,
      'downloaded' => _CertOrderStatus.downloaded,
      _ => _CertOrderStatus.inWork,
    };
    return _CertOrder(
      orderNumber: (j['order_number'] ?? '').toString(),
      type: (j['type'] ?? '').toString(),
      format: (j['format'] ?? '').toString(),
      where: (j['where'] ?? '').toString(),
      comment: (j['comment'] == null) ? null : j['comment'].toString(),
      status: parsed,
      createdAtMs: (j['created_at_ms'] is int) ? (j['created_at_ms'] as int) : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_number': orderNumber,
      'type': type,
      'format': format,
      'where': where,
      'comment': comment,
      'status': switch (status) {
        _CertOrderStatus.inWork => 'in_work',
        _CertOrderStatus.ready => 'ready',
        _CertOrderStatus.downloaded => 'downloaded',
      },
      'created_at_ms': createdAtMs,
    };
  }
}

