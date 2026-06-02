import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_ui.dart';
import '../../core/di/app_container.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api/edu_disclosure_api.dart';
import '../../data/api/upbringing_api.dart';
import '../../shared/widgets/app_header.dart';
import 'edu_disclosure_nav.dart';
import 'svedeniya_content_builder.dart';

/// Хаб «Сведения об ОО» — 11 корневых разделов (SVEDENIYA_OO_FULL.md §4).
class SvedeniyaHubPage extends StatefulWidget {
  const SvedeniyaHubPage({super.key});

  @override
  State<SvedeniyaHubPage> createState() => _SvedeniyaHubPageState();
}

class _SvedeniyaHubPageState extends State<SvedeniyaHubPage> {
  Map<String, dynamic> _disclosure = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cached = AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey);
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() => _disclosure = cached);
      }
      final fresh = await AppContainer.eduDisclosureApi.getDisclosure();
      await AppContainer.jsonCache.setJson(EduDisclosureApi.cacheKey, fresh);
      if (mounted) setState(() => _disclosure = fresh);
    } catch (_) {
      final cached = AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey);
      if (cached != null && mounted) setState(() => _disclosure = cached);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text('Сведения об ОО', style: appHeaderNestedTitleStyle),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: _load,
        child: _loading && _disclosure.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppUi.screenPaddingH,
                  AppUi.spacingL,
                  AppUi.screenPaddingH,
                  30,
                ),
                children: [
                  Text(
                    'ФГБОУ ВО «ДГУ» — колледж',
                    style: AppTextStyle.inter(
                      fontSize: 14,
                      color: AppColors.caption,
                    ),
                  ),
                  const SizedBox(height: AppUi.spacingM),
                  for (var i = 0; i < EduDisclosureNav.roots.length; i++) ...[
                    _NavTile(
                      title: EduDisclosureNav.roots[i].title,
                      enabled: _disclosure.isNotEmpty,
                      onTap: _disclosure.isEmpty
                          ? null
                          : () => context.push(
                                '/public/home/svedeniya/${EduDisclosureNav.roots[i].id}',
                                extra: _disclosure,
                              ),
                    ),
                    if (i != EduDisclosureNav.roots.length - 1)
                      const SizedBox(height: AppUi.spacingM),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Подразделы корневого пункта меню.
class SvedeniyaRootPage extends StatelessWidget {
  const SvedeniyaRootPage({super.key, required this.rootId, this.disclosure = const {}});

  final String rootId;
  final Map<String, dynamic> disclosure;

  @override
  Widget build(BuildContext context) {
    final root = EduDisclosureNav.rootById(rootId);
    if (root == null) {
      return Scaffold(
        appBar: AppHeader(
          leading: appHeaderNestedBackLeading(context),
          headerTitle: Text('Раздел', style: appHeaderNestedTitleStyle),
        ),
        body: Center(child: Text('Раздел не найден', style: AppTextStyle.inter())),
      );
    }

    final data = disclosure.isNotEmpty
        ? disclosure
        : AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey) ?? const {};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text(root.title, style: appHeaderNestedTitleStyle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppUi.screenPaddingH,
          AppUi.spacingL,
          AppUi.screenPaddingH,
          30,
        ),
        children: [
          for (var i = 0; i < root.children.length; i++) ...[
            _NavTile(
              title: root.children[i].title,
              onTap: () => context.push(
                '/public/home/svedeniya/$rootId/${root.children[i].id}',
                extra: data,
              ),
            ),
            if (i != root.children.length - 1) const SizedBox(height: AppUi.spacingM),
          ],
        ],
      ),
    );
  }
}

/// Контент подраздела.
class SvedeniyaContentPage extends StatefulWidget {
  const SvedeniyaContentPage({
    super.key,
    required this.rootId,
    required this.childId,
    this.disclosure = const {},
  });

  final String rootId;
  final String childId;
  final Map<String, dynamic> disclosure;

  @override
  State<SvedeniyaContentPage> createState() => _SvedeniyaContentPageState();
}

class _SvedeniyaContentPageState extends State<SvedeniyaContentPage> {
  Map<String, dynamic> _disclosure = const {};
  Map<String, dynamic> _upbringing = const {};
  Map<String, dynamic> _studentPortal = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _disclosure = _resolveDisclosure();
    _load();
  }

  Map<String, dynamic> _resolveDisclosure() {
    if (widget.disclosure.isNotEmpty) return widget.disclosure;
    return AppContainer.jsonCache.getJsonMap(EduDisclosureApi.cacheKey) ?? const {};
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_disclosure.isEmpty) {
        final fresh = await AppContainer.eduDisclosureApi.getDisclosure();
        await AppContainer.jsonCache.setJson(EduDisclosureApi.cacheKey, fresh);
        _disclosure = fresh;
      }
      if (widget.rootId == 'vospitatelnaya-deyatelnost') {
        final cached = AppContainer.jsonCache.getJsonMap(UpbringingApi.cacheKey);
        if (cached != null) _upbringing = cached;
        final fresh = await AppContainer.upbringingApi.getUpbringing();
        await AppContainer.jsonCache.setJson(UpbringingApi.cacheKey, fresh);
        _upbringing = fresh;
      }
      if (widget.rootId == 'studentam') {
        _studentPortal = await AppContainer.studentServicesApi.studentPortal();
      }
    } catch (_) {
      _disclosure = _resolveDisclosure();
      _upbringing = AppContainer.jsonCache.getJsonMap(UpbringingApi.cacheKey) ?? const {};
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String get _title {
    return EduDisclosureNav.childById(widget.rootId, widget.childId)?.title ?? 'Раздел';
  }

  @override
  Widget build(BuildContext context) {
    final widgets = SvedeniyaContentBuilder(
      rootId: widget.rootId,
      childId: widget.childId,
      disclosure: _disclosure,
      upbringing: _upbringing,
      studentPortal: _studentPortal,
    ).build();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        leading: appHeaderNestedBackLeading(context),
        headerTitle: Text(_title, style: appHeaderNestedTitleStyle),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppUi.screenPaddingH,
                  AppUi.spacingL,
                  AppUi.screenPaddingH,
                  30,
                ),
                children: widgets,
              ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.title, required this.onTap, this.enabled = true});

  final String title;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppUi.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppUi.spacingL, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyle.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: enabled ? AppColors.textPrimary : AppColors.caption,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron_right.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.chevronRight,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Совместимость со старым импортом роутера.
typedef ApplicantDisclosurePage = SvedeniyaHubPage;
