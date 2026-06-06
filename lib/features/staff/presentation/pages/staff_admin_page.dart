import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_ui.dart';
import '../../../../core/di/app_container.dart';
import '../../../../core/staff/staff_module_navigation.dart';
import '../../../../core/staff/staff_roles.dart';
import '../../../../data/models/staff_capabilities_model.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/api/api_exception.dart';
import '../../../../data/models/applicant_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/dismiss_keyboard_on_tap.dart';
import '../../../../shared/widgets/network_degraded_banner.dart';

/// Админка приёмной кампании: абитуриенты + проходной балл (только admin).
class StaffAdminPage extends StatefulWidget {
  const StaffAdminPage({super.key});

  @override
  State<StaffAdminPage> createState() => _StaffAdminPageState();
}

class _StaffAdminPageState extends State<StaffAdminPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _readRole();
  }

  void _readRole() {
    UserModel? me;
    final raw = AppContainer.jsonCache.getJsonMap('auth:me');
    if (raw != null) {
      try {
        me = UserModel.fromJson(raw);
      } catch (_) {}
    }
    final capsRaw = AppContainer.jsonCache.getJsonMap(StaffModuleNavigation.cacheKey);
    if (capsRaw != null) {
      try {
        _isAdmin = StaffCapabilitiesModel.fromJson(capsRaw).isAdmin;
      } catch (_) {
        _isAdmin = me?.isAdmin == true;
      }
    } else {
      _isAdmin = me?.isAdmin == true;
    }
    _tabController = TabController(length: _isAdmin ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isAdmin ? 'Панель управления' : 'Приёмная кампания';
    final tabs = _tabController;
    if (tabs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text(title, style: appHeaderNestedTitleStyle),
        showNotificationIcon: false,
      ),
      body: Column(
        children: [
          const NetworkDegradedBanner(),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: tabs,
              labelColor: AppColors.lightBlue,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.lightBlue,
              labelStyle: AppTextStyle.inter(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: [
                const Tab(text: 'Абитуриенты'),
                if (_isAdmin) const Tab(text: 'Проходной балл'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabs,
              children: [
                const _ApplicantsTab(),
                if (_isAdmin) const _PaymentCutoffTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantsTab extends StatefulWidget {
  const _ApplicantsTab();

  @override
  State<_ApplicantsTab> createState() => _ApplicantsTabState();
}

class _ApplicantsTabState extends State<_ApplicantsTab> {
  static const _pageSize = 50;
  static const _debounceMs = 400;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _debounce;
  List<ApplicantListItem> _items = [];
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    unawaited(_load(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      final q = _searchController.text.trim();
      if (q == _query) return;
      _query = q;
      unawaited(_load(reset: true));
    });
  }

  void _onScroll() {
    if (_loadingMore || _loading) return;
    if (_items.length >= _total) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      unawaited(_load(reset: false));
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items = [];
      });
    } else {
      if (_loadingMore) return;
      setState(() => _loadingMore = true);
    }
    try {
      final skip = reset ? 0 : _items.length;
      final page = await AppContainer.staffApi.getApplicants(
        search: _query.isEmpty ? null : _query,
        skip: skip,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items = page.items;
        } else {
          _items = [..._items, ...page.items];
        }
        _total = page.total;
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (reset) _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (reset) _error = 'Не удалось загрузить список';
      });
    }
  }

  Future<void> _openDetail(int id) async {
    try {
      final detail = await AppContainer.staffApi.getApplicant(id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => _ApplicantDetailSheet(detail: detail),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboardOnTap(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppUi.screenPaddingH,
              AppUi.spacingM,
              AppUi.screenPaddingH,
              AppUi.spacingS,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по ФИО, e-mail, телефону',
                prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUi.radiusL),
                  borderSide: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUi.radiusL),
                  borderSide: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppUi.screenPaddingH),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Найдено: $_total',
                  style: AppTextStyle.inter(fontSize: 13, color: AppColors.grey),
                ),
              ),
            ),
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _items.isEmpty
                    ? Center(
                        child: Text(
                          _error!,
                          style: AppTextStyle.inter(color: AppColors.grey),
                        ),
                      )
                    : _items.isEmpty
                        ? Center(
                            child: Text(
                              'Абитуриенты не найдены',
                              style: AppTextStyle.inter(color: AppColors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _load(reset: true),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                AppUi.screenPaddingH,
                                AppUi.spacingM,
                                AppUi.screenPaddingH,
                                24,
                              ),
                              itemCount: _items.length + (_loadingMore ? 1 : 0),
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppUi.spacingS),
                              itemBuilder: (context, index) {
                                if (index >= _items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final item = _items[index];
                                return _ApplicantRow(
                                  item: item,
                                  onTap: () => _openDetail(item.id),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantRow extends StatelessWidget {
  const _ApplicantRow({required this.item, required this.onTap});

  final ApplicantListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = item.examScore?.toStringAsFixed(2) ?? '—';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppUi.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppUi.spacingL),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fullName,
                      style: AppTextStyle.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      StaffRoles.applicantsStatusLabel(item.status),
                      style: AppTextStyle.inter(fontSize: 13, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.lightBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'балл',
                    style: AppTextStyle.inter(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicantDetailSheet extends StatelessWidget {
  const _ApplicantDetailSheet({required this.detail});

  final ApplicantDetail detail;

  Future<void> _launch(String? value) async {
    final v = value?.trim();
    if (v == null || v.isEmpty) return;
    final uri = v.contains('@')
        ? Uri(scheme: 'mailto', path: v)
        : Uri(scheme: 'tel', path: v);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            detail.fullName,
            style: AppTextStyle.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            StaffRoles.applicantsStatusLabel(detail.status),
            style: AppTextStyle.inter(color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'E-mail', value: detail.email, onTap: () => _launch(detail.email)),
          if ((detail.phone ?? '').isNotEmpty)
            _DetailRow(label: 'Телефон', value: detail.phone!, onTap: () => _launch(detail.phone)),
          if ((detail.phoneExtra ?? '').isNotEmpty)
            _DetailRow(
              label: 'Доп. телефон',
              value: detail.phoneExtra!,
              onTap: () => _launch(detail.phoneExtra),
            ),
          _DetailRow(
            label: 'Балл',
            value: detail.examScore?.toStringAsFixed(2) ?? '—',
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyle.inter(fontSize: 13, color: AppColors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: onTap != null ? AppColors.lightBlue : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}

class _PaymentCutoffTab extends StatefulWidget {
  const _PaymentCutoffTab();

  @override
  State<_PaymentCutoffTab> createState() => _PaymentCutoffTabState();
}

class _PaymentCutoffTabState extends State<_PaymentCutoffTab> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCutoff());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCutoff() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cutoff = await AppContainer.staffApi.getPaymentCutoff();
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (cutoff.cutoffScore != null) {
          _controller.text = cutoff.cutoffScore!.toStringAsFixed(2);
        }
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
        _error = 'Не удалось загрузить порог';
      });
    }
  }

  Future<void> _apply() async {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final score = double.tryParse(raw);
    if (score == null) {
      setState(() => _error = 'Введите число, например 4.35');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _resultMessage = null;
    });
    try {
      final result = await AppContainer.staffApi.setPaymentCutoff(score);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _resultMessage =
            'Порог ${result.cutoffScore.toStringAsFixed(2)} применён.\n'
            'Переведено на оплату: ${result.movedToPaymentCount}.\n'
            'Push отправлено: ${result.pushSent}, ошибок: ${result.pushFailed}.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Не удалось применить порог';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppUi.screenPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Абитуриенты с баллом не ниже порога будут переведены в статус «На оплату», '
            'зарегистрированным в приложении пользователям уйдёт push.',
            style: AppTextStyle.inter(fontSize: 14, height: 1.4, color: AppColors.grey),
          ),
          const SizedBox(height: AppUi.spacingL),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Проходной балл',
              hintText: '4.35',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppUi.radiusL),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: AppTextStyle.inter(color: Colors.red.shade700)),
          ],
          if (_resultMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppUi.spacingL),
              decoration: BoxDecoration(
                color: AppColors.backgroundBlue,
                borderRadius: BorderRadius.circular(AppUi.radiusL),
              ),
              child: Text(
                _resultMessage!,
                style: AppTextStyle.inter(fontSize: 14, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: AppUi.spacingL),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lightBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppUi.radiusL),
              ),
            ),
            onPressed: _submitting ? null : _apply,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Применить и уведомить',
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
