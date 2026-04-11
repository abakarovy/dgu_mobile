import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/app_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../shared/widgets/app_header.dart';

String _certDisplayType(String raw) {
  final k = raw.trim().toLowerCase();
  switch (k) {
    case 'education':
      return 'Об обучении';
    case 'archive':
      return 'Архивная справка';
    case 'scholarship':
      return 'О стипендии';
    case 'payment':
      return 'Об оплате';
    case 'call':
      return 'Вызов(по месту требования)';
  }
  final t = raw.trim();
  return t.isEmpty ? '—' : t;
}

String _certDisplayFormat(String raw) {
  final k = raw.trim().toLowerCase();
  switch (k) {
    case 'paper':
      return 'Бумажная';
    case 'electronic':
      return 'Электронная';
    case 'signature':
      return 'С электронной подписью';
  }
  final t = raw.trim();
  return t.isEmpty ? '—' : t;
}

class CertificateOrderPage extends StatefulWidget {
  const CertificateOrderPage({super.key});

  @override
  State<CertificateOrderPage> createState() => _CertificateOrderPageState();
}

class _CertificateOrderPageState extends State<CertificateOrderPage> {
  static const _prefsKey = 'profile:certificate_orders_v3';

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

  /// UI → API (`MOBILE_SPRAVKI_API.md`).
  static const Map<String, String> _typeRuToApi = {
    'Об обучении': 'education',
    'Архивная справка': 'archive',
    'О стипендии': 'scholarship',
    'Об оплате': 'payment',
    'Вызов(по месту требования)': 'call',
  };

  static const Map<String, String> _formatRuToApi = {
    'Бумажная': 'paper',
    'Электронная': 'electronic',
    'С электронной подписью': 'signature',
  };

  final _whereCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  late final FocusNode _whereFocus;
  late final FocusNode _commentFocus;
  void _onCertFieldFocus() {
    if (mounted) setState(() {});
  }

  String? _type;
  String? _format;
  bool _busy = false;
  bool _pdfDownloadBusy = false;

  bool get _uiBlocked => _busy || _pdfDownloadBusy;

  List<_CertOrder> _history = const [];
  String? _selectedOrderNumber;
  String _filterType = 'Все справки';

  /// Результат «Проверить статус» — под строкой «Номер заказа», без SnackBar.
  String? _statusCheckFeedback;
  bool _statusCheckFeedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _whereFocus = FocusNode();
    _commentFocus = FocusNode();
    _whereFocus.addListener(_onCertFieldFocus);
    _commentFocus.addListener(_onCertFieldFocus);
    _loadHistory();
  }

  @override
  void dispose() {
    _whereFocus.removeListener(_onCertFieldFocus);
    _commentFocus.removeListener(_onCertFieldFocus);
    _whereFocus.dispose();
    _commentFocus.dispose();
    _whereCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    var list = <_CertOrder>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? <String>[];
      for (final s in raw) {
        try {
          final j = jsonDecode(s);
          if (j is Map<String, dynamic>) list.add(_CertOrder.fromJson(j));
        } catch (_) {}
      }
      list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _history = list;
    });
    await _refreshOrdersFromApi(mergeWith: list);
  }

  /// История: `GET /api/documents/certificate-orders` (MOBILE_SPRAVKI_API.md).
  Future<void> _refreshOrdersFromApi({required List<_CertOrder> mergeWith}) async {
    try {
      final rows = await AppContainer.documentsApi.getCertificateOrders();
      final fromApi = <_CertOrder>[];
      for (final m in rows) {
        final o = _CertOrder.tryParseApi(m);
        if (o != null) fromApi.add(o);
      }
      fromApi.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
      if (!mounted) return;
      setState(() {
        _history = _mergeOrders(mergeWith, fromApi);
      });
    } catch (_) {
      // Оставляем уже показанные локальные заказы.
    }
  }

  /// Только для родителя: `student_id` в теле `POST /documents/certificate-order`.
  Future<int?> _parentStudentIdIfParent() async {
    try {
      final raw = await AppContainer.tokenStorage.getUserDataJson();
      if (raw == null || raw.isEmpty) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final role = (m['role'] ?? '').toString().trim().toLowerCase();
      if (role != 'parent') return null;
      final ls = await AppContainer.accountApi.getParentsLinkStatus();
      final sid = ls['student_id'];
      if (sid is int) return sid;
      if (sid is num) return sid.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Удалённые заказы + локальные; при совпадении `order_id` сервер важнее, кроме локального «Скачано».
  static List<_CertOrder> _mergeOrders(List<_CertOrder> local, List<_CertOrder> remote) {
    final map = <String, _CertOrder>{};
    for (final r in remote) {
      map[r.orderNumber] = r;
    }
    for (final l in local) {
      final r = map[l.orderNumber];
      if (r == null) {
        map[l.orderNumber] = l;
      } else if (l.status == _CertOrderStatus.downloaded) {
        map[l.orderNumber] = r.copyWith(status: _CertOrderStatus.downloaded);
      } else {
        map[l.orderNumber] = r;
      }
    }
    final merged = map.values.toList();
    merged.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return merged;
  }

  Future<void> _saveHistory(List<_CertOrder> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, [for (final o in list) jsonEncode(o.toJson())]);
    } catch (_) {}
  }

  void _replaceOrderInHistory(
    _CertOrder updated, {
    String? statusCheckFeedback,
    bool statusCheckFeedbackIsError = false,
  }) {
    setState(() {
      _history = [
        for (final e in _history)
          if (e.orderNumber == updated.orderNumber) updated else e,
      ];
      if (statusCheckFeedback != null) {
        _statusCheckFeedback = statusCheckFeedback;
        _statusCheckFeedbackIsError = statusCheckFeedbackIsError;
      }
    });
  }

  Future<void> _createOrder() async {
    if (_uiBlocked) return;
    final typeLabel = (_type ?? '').trim();
    final formatLabel = (_format ?? '').trim();
    final where = _whereCtrl.text.trim();
    final comment = _commentCtrl.text.trim();

    if (typeLabel.isEmpty || formatLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите тип и формат справки')),
      );
      return;
    }
    final apiType = _typeRuToApi[typeLabel];
    final apiFormat = _formatRuToApi[formatLabel];
    if (apiType == null || apiFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный тип или формат справки')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _statusCheckFeedback = null;
    });
    try {
      final parentSid = await _parentStudentIdIfParent();
      final res = await AppContainer.documentsApi.createCertificateOrder(
        type: apiType,
        format: apiFormat,
        where: where,
        comment: comment.isEmpty ? null : comment,
        studentId: parentSid,
      );
      final created = _CertOrder(
        orderNumber: res.orderId,
        type: typeLabel,
        format: formatLabel,
        where: where.isEmpty ? '—' : where,
        comment: comment.isEmpty ? null : comment,
        status: _CertOrderStatus.inWork,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        requestId: res.requestId,
      );
      final next = [
        created,
        ..._history.where((e) => e.orderNumber != created.orderNumber),
      ];
      setState(() {
        _history = next;
        _selectedOrderNumber = created.orderNumber;
      });
      await _saveHistory(next);
      if (!mounted) return;
      await _refreshOrdersFromApi(mergeWith: next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заказ создан. № ${res.orderId}')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusCheckFeedback = e.message;
        _statusCheckFeedbackIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  _CertOrder? get _currentOrder {
    final sel = (_selectedOrderNumber ?? '').trim();
    if (sel.isEmpty) return null;
    for (final o in _history) {
      if (o.orderNumber == sel) return o;
    }
    return null;
  }

  Future<void> _checkStatus() async {
    if (_uiBlocked) return;
    final o = _currentOrder;
    if (o == null) {
      setState(() {
        _statusCheckFeedback = _history.isEmpty
            ? 'История пустая'
            : 'Выберите заказ в списке ниже';
        _statusCheckFeedbackIsError = true;
      });
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await AppContainer.documentsApi.getCertificateOrderStatus(o.orderNumber);
      final nextStatus = res.isReady ? _CertOrderStatus.ready : _CertOrderStatus.inWork;
      final updated = o.copyWith(status: nextStatus);
      final msg = res.status.trim().isNotEmpty ? res.status : updated.statusLabel;
      _replaceOrderInHistory(
        updated,
        statusCheckFeedback: 'Статус: $msg',
        statusCheckFeedbackIsError: false,
      );
      await _saveHistory(_history);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusCheckFeedback = e.message;
        _statusCheckFeedbackIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_uiBlocked) return;
    final o = _currentOrder;
    if (o == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _history.isEmpty ? 'История пустая' : 'Выберите заказ в списке ниже',
          ),
        ),
      );
      return;
    }
    setState(() => _pdfDownloadBusy = true);
    try {
      final result = await AppContainer.documentsApi.downloadCertificatePdf(o.orderNumber);
      if (!result.hasFile) {
        if (!mounted) return;
        setState(() {
          _statusCheckFeedback =
              'Справка ещё не готова. Проверьте статус позже.';
          _statusCheckFeedbackIsError = true;
        });
        return;
      }
      final safe = o.orderNumber.replaceAll(RegExp(r'[^\w\-.]'), '_');
      final baseName = 'certificate_$safe';
      final bytes = Uint8List.fromList(result.bytes!);
      final savedPath = await _savePdfWithPicker(name: baseName, bytes: bytes);
      if (!mounted) return;
      if (savedPath == null || savedPath.isEmpty) {
        return;
      }
      final updated = o.copyWith(status: _CertOrderStatus.downloaded);
      _replaceOrderInHistory(updated);
      await _saveHistory(_history);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: $savedPath')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusCheckFeedback = e.message;
        _statusCheckFeedbackIsError = true;
      });
    } finally {
      if (mounted) setState(() => _pdfDownloadBusy = false);
    }
  }

  /// Диалог «Сохранить как» (где доступно); на Linux — сохранение в папку по умолчанию.
  Future<String?> _savePdfWithPicker({
    required String name,
    required Uint8List bytes,
  }) async {
    try {
      final p = await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      return p;
    } on UnimplementedError {
      return FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
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

  /// Как обводка у кнопки «Проверить статус» (`OutlinedButton` #2E63D5).
  static const Color _borderAccent = Color(0xFF2E63D5);
  static const Color _borderIdle = Color(0xFF000000);

  BoxDecoration _textFieldDecoration({required bool focused}) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: focused ? _borderAccent : _borderIdle,
        width: 1.5,
      ),
    );
  }

  BoxDecoration _dropdownDecoration() {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _borderAccent, width: 1.5),
    );
  }

  /// Открывает меню сразу под полем (как у нативного dropdown), а не снизу экрана.
  Future<String?> _pickFromAnchoredMenu({
    required BuildContext anchorContext,
    required String? selectedValue,
    required List<String> items,
  }) async {
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final overlay = Overlay.of(anchorContext).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final w = box.size.width;
    final h = box.size.height;
    final screenW = MediaQuery.sizeOf(anchorContext).width;

    return showMenu<String>(
      context: anchorContext,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(topLeft.dx, topLeft.dy + h, w, 0),
        Offset.zero & overlay.size,
      ),
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x40000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x24000000), width: 1),
      ),
      constraints: BoxConstraints(
        minWidth: w,
        maxWidth: screenW - 24,
        maxHeight: MediaQuery.sizeOf(anchorContext).height * 0.45,
      ),
      items: [
        for (final it in items)
          PopupMenuItem<String>(
            value: it,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Builder(
              builder: (_) {
                final selected = (selectedValue ?? '') == it;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0x0F2563EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: selected ? Border.all(color: const Color(0xFF2563EB), width: 1) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          it,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _fieldStyle.copyWith(
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                            color: const Color(0xFF000000),
                          ),
                        ),
                      ),
                      if (selected) const Icon(Icons.check_rounded, color: Color(0xFF2563EB), size: 20),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: Builder(
            builder: (anchorCtx) {
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _uiBlocked
                    ? null
                    : () async {
                        final picked = await _pickFromAnchoredMenu(
                          anchorContext: anchorCtx,
                          selectedValue: value,
                          items: items,
                        );
                        if (picked != null) onChanged(picked);
                      },
                child: Container(
                  decoration: _dropdownDecoration(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          (value == null || value.trim().isEmpty) ? 'Выберите' : value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (value == null || value.trim().isEmpty)
                              ? _fieldStyle.copyWith(color: const Color(0x4D000000))
                              : _fieldStyle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: _borderAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    int maxLines = 1,
  }) {
    final focused = focusNode.hasFocus;
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
          child: Container(
            decoration: _textFieldDecoration(focused: focused),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: maxLines == 1 ? Alignment.centerLeft : Alignment.topLeft,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !_uiBlocked,
              maxLines: maxLines,
              keyboardType: maxLines == 1 ? TextInputType.text : TextInputType.multiline,
              style: _fieldStyle,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: _fieldStyle.copyWith(color: const Color(0x4D000000)),
                contentPadding: EdgeInsets.symmetric(
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
        onPressed: _uiBlocked ? null : onTap,
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
    bool loading = false,
  }) {
    return SizedBox(
      height: 35,
      child: OutlinedButton(
        onPressed: _uiBlocked ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2E63D5), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF2E63D5),
                ),
              )
            : Text(
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
                focusNode: _whereFocus,
                hint: 'Например по месту работы',
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Комментарий (необязательно)',
                controller: _commentCtrl,
                focusNode: _commentFocus,
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
              if (_statusCheckFeedback != null) ...[
                const SizedBox(height: 6),
                Text(
                  _statusCheckFeedback!,
                  style: AppTextStyle.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.25,
                    color: _statusCheckFeedbackIsError
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF2E63D5),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _primaryButton(text: 'Создать заказ в 1С', onTap: _createOrder),
              const SizedBox(height: 10),
              _secondaryButton(text: 'Проверить статус', onTap: _checkStatus),
              const SizedBox(height: 10),
              _secondaryButton(
                text: 'Скачать PDF',
                onTap: _downloadPdf,
                loading: _pdfDownloadBusy,
              ),
              const SizedBox(height: 18),
              _dropdown(
                label: 'История справок',
                value: _filterType,
                items: <String>['Все справки', ..._types],
                onChanged: (v) {
                  final next = (v ?? '').trim();
                  if (next.isEmpty) return;
                  setState(() => _filterType = next);
                },
              ),
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
          _statusCheckFeedback = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0x24000000),
            width: 1,
          ),
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

/// Разбор статуса и даты из ответа API / 1С.
abstract final class _CertOrderStatusX {
  static _CertOrderStatus fromApiString(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return _CertOrderStatus.inWork;
    if (s.contains('скач') || s == 'downloaded') return _CertOrderStatus.downloaded;
    if (s == 'pending' || s == 'created' || s.contains('ожид') || s.contains('работ')) {
      return _CertOrderStatus.inWork;
    }
    if (s == 'done' ||
        s.contains('готов') ||
        s == 'ready' ||
        s == 'completed' ||
        s == 'выполнен') {
      return _CertOrderStatus.ready;
    }
    if (s == 'in_work' || s == 'new' || s == 'processing' || s == 'issued') {
      return _CertOrderStatus.inWork;
    }
    return _CertOrderStatus.inWork;
  }

  static int parseCreatedMs(Map<String, dynamic> j) {
    final ms = j['created_at_ms'] ?? j['createdAtMs'];
    if (ms is int) return ms;
    if (ms is num) return ms.toInt();
    final iso = j['created_at'] ?? j['date'] ?? j['created'] ?? j['Дата'];
    if (iso != null) {
      final dt = DateTime.tryParse(iso.toString());
      if (dt != null) return dt.millisecondsSinceEpoch;
    }
    return 0;
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
    this.requestId,
  });

  final String orderNumber;
  final String type;
  final String format;
  final String where;
  final String? comment;
  final _CertOrderStatus status;
  final int createdAtMs;
  final int? requestId;

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
      requestId: requestId,
    );
  }

  factory _CertOrder.fromJson(Map<String, dynamic> j) {
    final rid = j['request_id'] ?? j['requestId'];
    return _CertOrder(
      orderNumber: (j['order_id'] ?? j['order_number'] ?? '').toString(),
      type: (j['type'] ?? '').toString(),
      format: (j['format'] ?? '').toString(),
      where: (j['where'] ?? '').toString(),
      comment: (j['comment'] == null) ? null : j['comment'].toString(),
      status: _CertOrderStatusX.fromApiString((j['status'] ?? '').toString()),
      createdAtMs: _CertOrderStatusX.parseCreatedMs(j),
      requestId: rid is int ? rid : (rid is num ? rid.toInt() : null),
    );
  }

  /// Ответ `GET /documents/certificate-orders` (не путать с `GET /api/1c/orders`).
  static _CertOrder? tryParseApi(Map<String, dynamic> j) {
    if (!_isDocumentsCertificateRow(j)) return null;
    final orderNumber = _firstString(j, const [
      'order_id',
      'order_number',
      'orderNumber',
    ]);
    if (orderNumber.isEmpty) return null;
    final typeRaw = _firstString(j, const [
      'certificate_type',
      'type',
      'kind',
      'ВидСправки',
      'вид',
      'title',
    ]);
    final typeDisplay =
        RegExp(r'[а-яА-ЯёЁ]').hasMatch(typeRaw) ? typeRaw : _certDisplayType(typeRaw);
    final formatRaw = _firstString(j, const [
      'delivery_format',
      'format',
      'Формат',
      'format_name',
    ]);
    final formatDisplay =
        RegExp(r'[а-яА-ЯёЁ]').hasMatch(formatRaw) ? formatRaw : _certDisplayFormat(formatRaw);
    final where = _firstString(j, const [
      'present_where',
      'where',
      'purpose',
      'destination',
      'куда',
      'Куда',
      'recipient',
    ]);
    final commentRaw = j['comment'] ?? j['note'] ?? j['Комментарий'];
    final commentStr = commentRaw == null ? '' : commentRaw.toString().trim();
    final comment = commentStr.isEmpty ? null : commentStr;
    final status = _CertOrderStatusX.fromApiString((j['status'] ?? j['state'] ?? '').toString());
    final createdAtMs = _CertOrderStatusX.parseCreatedMs(j);
    final rid = j['request_id'] ?? j['requestId'];
    return _CertOrder(
      orderNumber: orderNumber,
      type: typeDisplay.isEmpty ? '—' : typeDisplay,
      format: formatDisplay.isEmpty ? '—' : formatDisplay,
      where: where.isEmpty ? '—' : where,
      comment: comment,
      status: status,
      createdAtMs: createdAtMs,
      requestId: rid is int ? rid : (rid is num ? rid.toInt() : null),
    );
  }

  /// Отсекает строки из `GET /api/1c/orders` (приказы о движении контингента и т.п.).
  static bool _isDocumentsCertificateRow(Map<String, dynamic> j) {
    if (j.containsKey('number') &&
        j['order_id'] == null &&
        j['certificate_type'] == null &&
        j['delivery_format'] == null &&
        j['present_where'] == null) {
      return false;
    }
    final blob = '${j['type'] ?? ''} ${j['certificate_type'] ?? ''}'.toLowerCase();
    if (blob.contains('приказ') && blob.contains('контингент')) return false;
    return true;
  }

  static String _firstString(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderNumber,
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
      if (requestId != null) 'request_id': requestId,
    };
  }
}

